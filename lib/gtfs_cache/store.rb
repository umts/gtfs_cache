require_relative "remote"

module GtfsCache
  module Store
    class << self
      def gtfs_schedule = cache.read("gtfs")

      def gtfs_realtime_alerts = cache.read("gtfs_realtime_alerts")

      def gtfs_realtime_trip_updates = cache.read("gtfs_realtime_trip_updates")

      def refresh_gtfs_schedule = Remote.gtfs_schedule&.then { |data| cache.write("gtfs", data) }

      def refresh_gtfs_realtime_alerts
        Remote.gtfs_realtime_alerts&.then { |data| cache.write("gtfs_realtime_alerts", data) }
      end

      def refresh_gtfs_realtime_trip_updates
        Remote.gtfs_realtime_trip_updates&.then { |data| cache.write("gtfs_realtime_trip_updates", data) }
      end

      private

      def cache
        @cache ||= case ENV.fetch("RACK_ENV", "development")
                   when "production"
                     # :nocov:
                     ActiveSupport::Cache::RedisCacheStore.new(url: "redis://gtfs_cache-redis:6379/0",
                                                               namespace: "gtfs_cache")
                     # :nocov:
                   when "development"
                     # :nocov:
                     ActiveSupport::Cache::MemoryStore.new
                     # :nocov:
                   else
                     ActiveSupport::Cache::NullStore.new
                   end
      end
    end
  end
end
