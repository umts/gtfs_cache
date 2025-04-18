require "gtfs_cache"

RSpec.describe GtfsCache do
  include Rack::Test::Methods

  let(:app) { described_class::App }

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
