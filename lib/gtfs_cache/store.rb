require_relative "entry"
require_relative "remote"

module GtfsCache
  module Store
    class << self
      def gtfs_schedule = read(:gtfs_schedule)

      def gtfs_schedule_routes = read(:gtfs_schedule_routes)

      def gtfs_realtime_alerts = read(:gtfs_realtime_alerts)

      def gtfs_realtime_trip_updates = read(:gtfs_realtime_trip_updates)

      def check_for_updates
        update_gtfs_schedule unless read(:gtfs_schedule)&.fresh?
        update_gtfs_realtime_alerts unless read(:gtfs_realtime_alerts)&.fresh?
        update_gtfs_realtime_trip_updates unless read(:gtfs_realtime_trip_updates)&.fresh?
      end

      private

      def redis
        @redis ||= ConnectionPool.new(size: 5) do
          redis = if ENV.fetch("RACK_ENV", "development") == "development"
                    # :nocov:
                    MockRedis.new
                    # :nocov:
                  else
                    Redis.new(url: "redis://gtfs_cache-redis:6379/0")
                  end
          Redis::Namespace.new(:gtfs_cache, redis:)
        end
      end

      def read(key)
        redis.with do |conn|
          conn.get("#{key}:data")&.then do |data|
            etag = conn.get("#{key}:etag")
            time = conn.get("#{key}:time")&.then { |time| Time.at(time.to_i) }
            expires = conn.get("#{key}:expires")&.then { |time| Time.at(time.to_i) }
            Entry.new(data:, etag:, time:, expires:)
          end
        end
      end

      def write(key, data, time: Time.current, expires_in: 0.seconds)
        etag = Digest::MD5.hexdigest(data)
        expires = expires_in.after(time)

        redis.with do |conn|
          conn.multi do |transaction|
            transaction.set("#{key}:expires", expires.to_i)
            next unless etag != conn.get("#{key}:etag")

            transaction.mset("#{key}:data", data, "#{key}:etag", etag, "#{key}:time", time.to_i)
          end
        end
      end

      def update_gtfs_schedule
        Remote.gtfs_schedule&.then do |data|
          time = Time.current
          write(:gtfs_schedule, data, time:, expires_in: 1.day)
          Zip::File.open_buffer(data) do |zip|
            write(:gtfs_schedule_routes, zip.find_entry("routes.txt").get_input_stream.read, time:, expires_in: 1.day)
          end
        end
      end

      def update_gtfs_realtime_alerts
        Remote.gtfs_realtime_alerts&.then do |data|
          write(:gtfs_realtime_alerts, data, expires_in: 10.seconds)
        end
      end

      def update_gtfs_realtime_trip_updates
        Remote.gtfs_realtime_trip_updates&.then do |data|
          write(:gtfs_realtime_trip_updates, data, expires_in: 10.seconds)
        end
      end
    end
  end
end
