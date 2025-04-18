require "gtfs_cache"

RSpec.describe GtfsCache do
  include Rack::Test::Methods

  let(:app) { described_class::App }

  describe "GET /gtfs" do
    subject(:call) { get "/gtfs" }

    context "when data has not been cached" do
      before { stub_request(:get, "https://www.pvta.com/g_trans/google_transit.zip").to_return(body: "server data") }

      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with data from the public gtfs feed" do
        call
        expect(last_response.body).to eq("server data")
      end
    end

    context "when data has been cached" do
      before { allow(GtfsCache::Cache.store).to receive(:fetch).with("gtfs", any_args).and_return("cache data") }

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
      before do
        allow(CREDENTIALS).to receive(:swiftly_api_key).and_return('test-api-key')
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates")
          .with(headers: { 'Authorization' => 'test-api-key' })
          .to_return(body: "server data")
      end

      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with data from the public gtfs feed" do
        call
        expect(last_response.body).to eq("server data")
      end
    end

    context "when data has been cached" do
      before do
        allow(GtfsCache::Cache.store).to receive(:fetch).with("gtfs_realtime_trip_updates", any_args)
                                                        .and_return("cache data")
      end

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
