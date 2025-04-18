require_relative "cache"
require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    get "/gtfs" do
      Cache.gtfs
    end

    get "/gtfs-rt/alerts" do
      Cache.gtfs_realtime_alerts
    end

    get "/gtfs-rt/trip-updates" do
      Cache.gtfs_realtime_trip_updates
    end

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
