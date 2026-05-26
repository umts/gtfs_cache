require "gtfs_cache/app"

RSpec.describe GtfsCache::App do
  include Rack::Test::Methods

  let(:app) { described_class }

  shared_examples "a store endpoint" do |store_key: nil, content_type: nil|
    context "when data has not been cached" do
      it "responds with a service unavailable status" do
        subject
        expect(last_response.status).to eq(503)
      end
    end

    context "when data has been cached without cache control info" do
      before { redis.set("#{store_key}:data", "cached data") }

      it "responds with an ok status" do
        subject
        expect(last_response.status).to eq(200)
      end

      it "responds with a body containing the cached data" do
        subject
        expect(last_response.body).to eq("cached data")
      end

      it "responds with the corresponding content type header" do
        subject
        expect(last_response.headers).to include("Content-Type" => matching(content_type))
      end

      it "responds with headers that strictly disallow client side caching" do
        subject
        expect(last_response.headers).to include(
          "Cache-Control" => matching("no-store").and(matching("no-cache")).and(matching("must-revalidate")),
          "Pragma" => "no-cache",
          "Expires" => "0"
        )
      end
    end
  end

  describe "GET /gtfs" do
    subject(:call) { get "/gtfs" }

    it_behaves_like "a store endpoint", store_key: "gtfs_schedule", content_type: "application/zip"
  end

  describe "GET /gtfs.zip" do
    subject(:call) { get "/gtfs.zip" }

    it_behaves_like "a store endpoint", store_key: "gtfs_schedule", content_type: "application/zip"
  end

  describe "GET /gtfs/routes" do
    subject(:call) { get "/gtfs/routes" }

    it_behaves_like "a store endpoint", store_key: "gtfs_schedule_routes", content_type: "text/csv"
  end

  describe "GET /gtfs/routes.txt" do
    subject(:call) { get "/gtfs/routes.txt" }

    it_behaves_like "a store endpoint", store_key: "gtfs_schedule_routes", content_type: "text/csv"
  end

  describe "GET /gtfs-rt/alerts" do
    subject(:call) { get "/gtfs-rt/alerts" }

    it_behaves_like "a store endpoint", store_key: "gtfs_realtime_alerts", content_type: "application/protobuf"
  end

  describe "GET /gtfs-rt/trip-updates" do
    subject(:call) { get "/gtfs-rt/trip-updates" }

    it_behaves_like "a store endpoint", store_key: "gtfs_realtime_trip_updates", content_type: "application/protobuf"
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
