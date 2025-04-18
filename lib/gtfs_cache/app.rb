module GtfsCache
  class App < Sinatra::Base
    get "/up" do
      200
    end

    get "/*" do
      404
    end
  end
end
