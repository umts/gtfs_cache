require_relative "remote"

module GtfsCache
  module Store
    class << self
      def gtfs_schedule = read(:gtfs_schedule)

      def gtfs_realtime_alerts = read(:gtfs_realtime_alerts)

      def gtfs_realtime_trip_updates = read(:gtfs_realtime_trip_updates)

      def check_for_updates
        update_gtfs_schedule if stale?(:gtfs_schedule)
        update_gtfs_realtime_alerts if stale?(:gtfs_realtime_alerts)
        update_gtfs_realtime_trip_updates if stale?(:gtfs_realtime_trip_updates)
      end

      private

      def redis
        @redis ||= ConnectionPool.new do
          if ENV.fetch("RACK_ENV", "development") == "development"
            # :nocov:
            MockRedis.new
            # :nocov:
          else
            Redis::Namespace.new(:gtfs_cache, redis: Redis.new(url: "redis://gtfs_cache-redis:6379/0"))
          end
        end
      end

      def read(key) = redis.with { |conn| conn.get("#{key}:data") }

      def write(key, data, expires_in: 0)
        redis.with do |conn|
          conn.set("#{key}:data", data)
          conn.set("#{key}:time", (Time.current + expires_in).to_i)
        end
      end

      def stale?(key)
        redis.with do |conn|
          data = conn.get("#{key}:data")
          return true if data.blank?

          time = conn.get("#{key}:time")
          time.blank? || Time.zone.at(time.to_i) < Time.current
        end
      end

      def update_gtfs_schedule
        Remote.gtfs_schedule&.then do |data|
          write(:gtfs_schedule, data, expires_in: 1.day)
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
