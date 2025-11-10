require "net/http"

module GtfsCache
  module Store
    class << self
      def gtfs = store.read("gtfs")

      def refresh_gtfs
        response = Net::HTTP.get_response(URI.parse(gtfs_url))
        return unless response.is_a?(Net::HTTPSuccess)

        store.write("gtfs", response.body)
      end

      def gtfs_realtime_alerts = store.read("gtfs_realtime_alerts")

      def refresh_gtfs_realtime_alerts
        response = Net::HTTP.get_response(
          URI.parse(gtfs_realtime_alerts_url),
          { "Authorization" => CREDENTIALS.swiftly_api_key }
        )
        return unless response.is_a?(Net::HTTPSuccess)

        store.write("gtfs_realtime_alerts", response.body)
      end

      def gtfs_realtime_trip_updates = store.read("gtfs_realtime_trip_updates")

      def refresh_gtfs_realtime_trip_updates
        response = Net::HTTP.get_response(
          URI.parse(gtfs_realtime_trip_updates_url),
          { "Authorization" => CREDENTIALS.swiftly_api_key }
        )
        return unless response.is_a?(Net::HTTPSuccess)

        store.write("gtfs_realtime_trip_updates", response.body)
      end

      private

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

      def swiftly_base_url
        if ENV.fetch("RACK_ENV", "development") == "development"
          # :nocov:
          "https://api.goswift.ly/real-time/pioneer-valley-pvta-sandbox"
          # :nocov:
        else
          "https://api.goswift.ly/real-time/pioneer-valley-pvta"
        end
      end

      def gtfs_url = "https://www.pvta.com/g_trans/google_transit.zip"

      def gtfs_realtime_alerts_url = File.join(swiftly_base_url, "gtfs-rt-alerts/v2")

      def gtfs_realtime_trip_updates_url = File.join(swiftly_base_url, "gtfs-rt-trip-updates")
    end
  end
end
