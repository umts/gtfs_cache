require "gtfs_cache"

RSpec.describe GtfsCache do
  include Rack::Test::Methods

  let(:app) { described_class::App }

  describe "GET /gtfs/:file" do
    subject(:call) { get "/gtfs/#{file}" }

    let(:file) { "routes" }

    before do
      zip_file = Zip::OutputStream.write_buffer do |zio|
        zio.put_next_entry("routes.txt")
        zio.write "route file content"
      end.string
      stub_request(:get, "https://www.pvta.com/g_trans/google_transit.zip").to_return(body: zip_file)
    end

    context "when file is a valid gtfs file and data has not been cached" do
      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with data from the public gtfs feed" do
        call
        expect(last_response.body).to eq("route file content")
      end
    end

    context "when file is a valid gtfs file and data has been cached" do
      before do
        allow(GtfsCache::Cache.store).to receive(:fetch).with("gtfs", expires_in: 1.day)
                                                        .and_return({ "routes" => "cached file content" })
      end

      it "responds with an ok status" do
        call
        expect(last_response.status).to eq(200)
      end

      it "responds with the cached data" do
        call
        expect(last_response.body).to eq("cached file content")
      end
    end

    context "when file is not a valid gtfs file" do
      let(:file) { "invalid_file" }

      it "responds with a not found status" do
        call
        expect(last_response.status).to eq(404)
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
