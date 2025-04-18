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

      def gtfs
        store.fetch("gtfs", expires_in: 1.day) do
          Net::HTTP.get(URI.parse("https://www.pvta.com/g_trans/google_transit.zip"))
        end
      end

      def gtfs_realtime_alerts
        store.fetch("gtfs_realtime_alerts", expires_in: 15.seconds) do
          Net::HTTP.get(
            URI.parse("https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-alerts/v2"),
            { "Authorization" => CREDENTIALS.swiftly_api_key }
          )
        end
      end

      def gtfs_realtime_trip_updates
        store.fetch("gtfs_realtime_trip_updates", expires_in: 15.seconds) do
          Net::HTTP.get(
            URI.parse("https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates"),
            { "Authorization" => CREDENTIALS.swiftly_api_key }
          )
        end
      end
    end
  end
end
