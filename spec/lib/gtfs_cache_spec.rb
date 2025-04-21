require "gtfs_cache"

RSpec.describe GtfsCache do
  include Rack::Test::Methods

  let(:app) { described_class::App }
  let(:store) { instance_double(ActiveSupport::Cache::Store) }

  describe "GET /gtfs" do
    subject(:call) { get "/gtfs" }

    context "when data has not been cached" do
      before { allow(GtfsCache::Store).to receive(:gtfs).and_return(nil) }

      it "responds with a service unavailable status" do
        call
        expect(last_response.status).to eq(503)
      end
    end

    context "when data has been cached" do
      before { allow(GtfsCache::Store).to receive(:gtfs).and_return("cache data") }

      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with the cached data" do
        call
        expect(last_response.body).to eq("cache data")
      end
    end
  end

  describe "GET /gtfs-rt/alerts" do
    subject(:call) { get "/gtfs-rt/alerts" }

    context "when data has not been cached" do
      before { allow(GtfsCache::Store).to receive(:gtfs_realtime_alerts).and_return(nil) }

      it "responds with a service unavailable status" do
        call
        expect(last_response.status).to eq(503)
      end
    end

    context "when data has been cached" do
      before { allow(GtfsCache::Store).to receive(:gtfs_realtime_alerts).and_return("cache data") }

      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with the cached data" do
        call
        expect(last_response.body).to eq("cache data")
      end
    end
  end

  describe "GET /gtfs-rt/trip-updates" do
    subject(:call) { get "/gtfs-rt/trip-updates" }

    context "when data has not been cached" do
      before { allow(GtfsCache::Store).to receive(:gtfs_realtime_trip_updates).and_return(nil) }

      it "responds with a service unavailable status" do
        call
        expect(last_response.status).to eq(503)
      end
    end

    context "when data has been cached" do
      before { allow(GtfsCache::Store).to receive(:gtfs_realtime_trip_updates).and_return("cache data") }

      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with the cached data" do
        call
        expect(last_response.body).to eq("cache data")
      end
    end
  end

  describe "GET /up" do
    subject(:call) { get "/up" }

    it "responds with an ok status" do
      call
      expect(last_response.status).to eq(200)
    end
  end

  describe "GET /unrecognized_path" do
    subject(:call) { get "/unrecognized_path" }

    it "responds with a not found status" do
      call
      expect(last_response.status).to eq(404)
    end
  end
end
