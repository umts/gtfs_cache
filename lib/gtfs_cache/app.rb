require_relative "store"
require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    helpers do
      def serve_entry(entry, content_type)
        return 503 if entry.blank?

        unless entry.fresh?
          headers "Cache-Control" => "no-store, no-cache, must-revalidate", "Pragma" => "no-cache", "Expires" => "0"
        end

        self.content_type content_type
        entry.data
      end
    end

    before do
      headers "Access-Control-Allow-Origin" => "*"
    end

    get "/gtfs(.zip)?" do
      serve_entry Store.gtfs_schedule, "application/zip"
    end

    get "/gtfs/routes(.txt)?" do
      serve_entry Store.gtfs_schedule_routes, "text/csv"
    end

    get "/gtfs-rt/alerts" do
      serve_entry Store.gtfs_realtime_alerts, "application/protobuf"
    end

    get "/gtfs-rt/trip-updates" do
      serve_entry Store.gtfs_realtime_trip_updates, "application/protobuf"
    end

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
