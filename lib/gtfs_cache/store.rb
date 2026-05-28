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
        check_gtfs_schedule
        check_gtfs_realtime_alerts
        check_gtfs_realtime_trip_updates
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
            expires = conn.get("#{key}:expires")
            Entry.new(data:, expires: expires && Time.at(expires.to_i))
          end
        end
      end

      def write(key, data, expires: Time.current)
        redis.with do |conn|
          conn.multi do |transaction|
            transaction.set("#{key}:data", data)
            transaction.set("#{key}:expires", expires.to_i)
          end
        end
      end

      def check_gtfs_schedule
        return if %i[gtfs_schedule gtfs_schedule_routes].map { |key| read(key)&.fresh? }.all?

        Remote.gtfs_schedule&.then do |data|
          expires = 1.day.from_now
          write(:gtfs_schedule, data, expires:) unless read(:gtfs_schedule)&.fresh?
          check_gtfs_schedule_subfiles(data, expires)
        end
      end

      def check_gtfs_schedule_subfiles(data, expires)
        return if read(:gtfs_schedule_routes)&.fresh?

        Zip::File.open_buffer(data) do |zip_file|
          write(:gtfs_schedule_routes, zip_file.find_entry("routes.txt").get_input_stream.read, expires:)
        end
      end

      def check_gtfs_realtime_alerts
        return if read(:gtfs_realtime_alerts)&.fresh?

        Remote.gtfs_realtime_alerts&.then do |data|
          write(:gtfs_realtime_alerts, data, expires: 10.seconds.from_now)
        end
      end

      def check_gtfs_realtime_trip_updates
        return if read(:gtfs_realtime_trip_updates)&.fresh?

        Remote.gtfs_realtime_trip_updates&.then do |data|
          write(:gtfs_realtime_trip_updates, data, expires: 10.seconds.from_now)
        end
      end
    end
  end
end
