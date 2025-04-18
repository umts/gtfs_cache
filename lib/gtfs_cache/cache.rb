require "net/http"

module GtfsCache
  module Cache
    class << self
      def store
        @store ||= if ENV.fetch("RACK_ENV", "development") == "test"
                     ActiveSupport::Cache::NullStore.new
                   else
                     # :nocov:
                     ActiveSupport::Cache::FileStore.new(Pathname(__dir__).join("../../tmp/cache").expand_path)
                     # :nocov:
                   end
      end

      def gtfs
        store.fetch("gtfs", expires_in: 1.day) do
          Net::HTTP.get(URI.parse("https://www.pvta.com/g_trans/google_transit.zip"))
        end
      end
    end
  end
end
