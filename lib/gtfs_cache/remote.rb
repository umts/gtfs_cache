require "net/http"

module GtfsCache
  module Remote
    class << self
      def gtfs_schedule = fetch_from("https://www.pvta.com/g_trans/google_transit.zip")

      def gtfs_realtime_alerts = fetch_from_swiftly("gtfs-rt-alerts/v2")

      def gtfs_realtime_trip_updates = fetch_from_swiftly("gtfs-rt-trip-updates")

      private

      def fetch_from(url, headers = {})
        response = Net::HTTP.get_response(URI.parse(url), headers)
        return nil unless response.is_a?(Net::HTTPOK)

        response.body
      end

      def fetch_from_swiftly(path)
        fetch_from(File.join(swiftly_base_url, path), { "Authorization" => CREDENTIALS.swiftly_api_key })
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
    end
  end
end
