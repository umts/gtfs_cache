require_relative "cache"
require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    get "/gtfs/:file" do
      Cache.gtfs_data(params[:file]).presence || 404
    end

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
