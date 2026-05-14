require_relative "store"
require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    before do
      headers "Access-Control-Allow-Origin" => "*"
    end

    get "/gtfs(.zip)?" do
      data = Store.gtfs.presence
      next 503 if data.blank?

      content_type "application/zip"
      data
    end

    get "/gtfs-rt/alerts" do
      data = Store.gtfs_realtime_alerts.presence
      next 503 if data.blank?

      content_type "application/protobuf"
      data
    end

    get "/gtfs-rt/trip-updates" do
      data = Store.gtfs_realtime_trip_updates.presence
      next 503 if data.blank?

      content_type "application/protobuf"
      data
    end

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
