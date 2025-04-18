require_relative "logger"

module GtfsCache
  class App < Sinatra::Base
    register Logger

    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
