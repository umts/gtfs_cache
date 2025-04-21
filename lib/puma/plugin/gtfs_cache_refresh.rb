require "gtfs_cache/store"
require "puma/plugin"

module Puma
  class Plugin
    class GtfsCacheRefresh < Plugin
      def start(_)
        in_background do
          loop do
            refresh_gtfs_if_needed
            refresh_gtfs_realtime_if_needed
          rescue StandardError => e
            e
          ensure
            sleep 1
          end
        end
      end

      private

      def refresh_gtfs_if_needed
        current_time = Time.now.to_i
        return if @last_gtfs_refresh.present? && (current_time - @last_gtfs_refresh) < 1.day

        @last_gtfs_refresh = current_time
        GtfsCache::Store.refresh_gtfs
      end

      def refresh_gtfs_realtime_if_needed
        current_time = Time.now.to_i
        return if @last_gtfs_realtime_refresh.present? && (current_time - @last_gtfs_realtime_refresh) < 10.seconds

        @last_gtfs_realtime_refresh = current_time
        GtfsCache::Store.refresh_gtfs_realtime_alerts
        GtfsCache::Store.refresh_gtfs_realtime_trip_updates
      end
    end
  end
end

Puma::Plugins.register("gtfs_cache_refresh", Puma::Plugin::GtfsCacheRefresh)
