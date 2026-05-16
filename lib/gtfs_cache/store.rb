require_relative "remote"

module GtfsCache
  module Store
    class << self
      def gtfs_schedule = redis.get("gtfs_schedule:data")

      def gtfs_realtime_alerts = redis.get("gtfs_realtime_alerts:data")

      def gtfs_realtime_trip_updates = redis.get("gtfs_realtime_trip_updates:data")

      def keep_warm
        refresh_gtfs_schedule
        refresh_gtfs_realtime_alerts
        refresh_gtfs_realtime_trip_updates
      end

      private

      def redis
        @redis ||= case ENV.fetch("RACK_ENV", "development")
                   when "production"
                     # :nocov:
                     ConnectionPool.new do
                       Redis::Namespace.new(:gtfs_cache, redis: Redis.new(url: "redis://gtfs_cache-redis:6379/0"))
                     end
                     # :nocov:
                   else
                     MockRedis.new
                   end
      end

      def refresh_gtfs_schedule
        data = redis.get("gtfs_schedule:data")
        time = redis.get("gtfs_schedule:time")

        return unless data.nil? || time.nil? || Time.current - Time.at(time) >= 1.day

        Remote.gtfs_schedule&.then do |new_data|
          redis.set("gtfs_schedule:data", new_data)
          redis.set("gtfs_schedule:time", Time.current.to_i)
        end
      end

      def refresh_gtfs_realtime_alerts
        data = redis.get("gtfs_realtime_alerts:data")
        time = redis.get("gtfs_realtime_alerts:time")

        return unless data.nil? || time.nil? || Time.current - Time.at(time) >= 10.seconds

        Remote.gtfs_realtime_alerts&.then do |new_data|
          redis.set("gtfs_realtime_alerts:data", new_data)
          redis.set("gtfs_realtime_alerts:time", Time.current.to_i)
        end
      end

      def refresh_gtfs_realtime_trip_updates
        data = redis.get("gtfs_realtime_trip_updates:data")
        time = redis.get("gtfs_realtime_trip_updates:time")

        return unless data.nil? || time.nil? || Time.current - Time.at(time) >= 10.seconds

        Remote.gtfs_realtime_trip_updates&.then do |new_data|
          redis.set("gtfs_realtime_trip_updates:data", new_data)
          redis.set("gtfs_realtime_trip_updates:time", Time.current.to_i)
        end
      end
    end
  end
end
