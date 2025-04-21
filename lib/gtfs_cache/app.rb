require_relative "store"
require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    before do
      headers "Access-Control-Allow-Origin" => "*"
    end

    get "/gtfs" do
      Store.gtfs.presence || 503
    end

    get "/gtfs-rt/alerts" do
      Store.gtfs_realtime_alerts.presence || 503
    end

    get "/gtfs-rt/trip-updates" do
      Store.gtfs_realtime_trip_updates || 503
    end

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
