require "net/http"

module GtfsCache
  module Cache
    class << self
      def store
        @store ||= case ENV.fetch("RACK_ENV", "development")
                   when "production"
                     # :nocov:
                     ActiveSupport::Cache::FileStore.new(Pathname(__dir__).join("../../tmp/cache").expand_path)
                     # :nocov:
                   when "development"
                     # :nocov:
                     ActiveSupport::Cache::MemoryStore.new
                     # :nocov:
                   else
                     ActiveSupport::Cache::NullStore.new
                   end
      end

      def gtfs = store.read("gtfs")

      def gtfs_realtime_alerts = store.fetch("gtfs_realtime_alerts")

      def gtfs_realtime_trip_updates = store.fetch("gtfs_realtime_trip_updates")

      def periodically_refresh
        last_gtfs_update = Time.now.to_i
        last_gtfs_realtime_update = Time.now.to_i
        loop do
          current_time = Time.now.to_i
          if gtfs.nil? || (current_time - last_gtfs_update).seconds >= 1.day
            refresh_gtfs_data
            last_gtfs_update = current_time
          end
          if gtfs_realtime_alerts.nil? || gtfs_realtime_trip_updates.nil? ||
             (current_time - last_gtfs_realtime_update).seconds >= 15.seconds
            refresh_gtfs_realtime_data
            last_gtfs_realtime_update = current_time
          end
          sleep 1
        end
      end

      private

      def refresh_gtfs_data
        store.write("gtfs", Net::HTTP.get(URI.parse("https://www.pvta.com/g_trans/google_transit.zip")))
      end

      def refresh_gtfs_realtime_data
        store.write(
          "gtfs_realtime_alerts",
          Net::HTTP.get(URI.parse("https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-alerts/v2"),
                        { "Authorization" => CREDENTIALS.swiftly_api_key })
        )
        store.write(
          "gtfs_realtime_trip_updates",
          Net::HTTP.get(URI.parse("https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates"),
                        { "Authorization" => CREDENTIALS.swiftly_api_key })
        )
      end
    end
  end
end
