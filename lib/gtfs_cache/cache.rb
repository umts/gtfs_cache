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

      def gtfs_data(file)
        file_data = store.fetch("gtfs", expires_in: 1.day) { fetch_gtfs_data }
        file_data[file]
      end

      private


      def fetch_gtfs_data
        {}.tap do |data|
          Zip::File.open_buffer(Net::HTTP.get(URI.parse("https://www.pvta.com/g_trans/google_transit.zip"))) do |zip|
            zip.each do |entry|
              data[File.basename(entry.name, File.extname(entry.name))] = entry.get_input_stream.read
            end
          end
        end
      end
    end
  end
end
