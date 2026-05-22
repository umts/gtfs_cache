require_relative "entry"
require_relative "remote"
require "zip"

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

      def update_gtfs_schedule
        Remote.gtfs_schedule&.then do |data|
          write(:gtfs_schedule, data, expires: 1.day.from_now)
          Zip::File.open_buffer(data) do |zip_file|
            routes_data = zip_file.find_entry("routes.txt").get_input_stream.read
            write(:gtfs_schedule_routes, routes_data, expires: 1.day.from_now)
          end
        end
      end

      def update_gtfs_realtime_alerts
        Remote.gtfs_realtime_alerts&.then do |data|
          write(:gtfs_realtime_alerts, data, expires: 10.seconds.from_now)
        end
      end

      def update_gtfs_realtime_trip_updates
        Remote.gtfs_realtime_trip_updates&.then do |data|
          write(:gtfs_realtime_trip_updates, data, expires: 10.seconds.from_now)
        end
      end
    end
  end
end
