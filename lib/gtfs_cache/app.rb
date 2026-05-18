require_relative "store"
require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    helpers do
      def serve_cached(data, content_type)
        return 503 if data.blank?

        self.content_type content_type
        data
      end
    end

    before do
      headers "Access-Control-Allow-Origin" => "*"
    end

    get "/gtfs(.zip)?" do
      serve_cached Store.gtfs, "application/zip"
    end

    get "/gtfs-rt/alerts" do
      serve_cached Store.gtfs_realtime_alerts, "application/protobuf"
    end

    get "/gtfs-rt/trip-updates" do
      serve_cached Store.gtfs_realtime_trip_updates, "application/protobuf"
    end

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
