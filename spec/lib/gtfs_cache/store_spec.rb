require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  let(:internal_store) { described_class.send(:store) }

  describe ".gtfs" do
    subject(:call) { described_class.gtfs }

    before { allow(internal_store).to receive(:read).with("gtfs").and_return("cached data") }

    it "returns the cached value for gtfs" do
      expect(call).to eq("cached data")
    end
  end

  describe ".refresh_gtfs" do
    subject(:call) { described_class.refresh_gtfs }

    before { allow(internal_store).to receive(:write).with("gtfs", anything).and_return(nil) }

    context "when the pvta gtfs endpoint responds successfully" do
      before do
        stub_request(:get, "https://www.pvta.com/g_trans/google_transit.zip")
          .to_return(status: 200, body: "server data")
      end

      it "writes the request body to the store" do
        call
        expect(internal_store).to have_received(:write).with("gtfs", "server data")
      end
    end

    context "when the pvta gtfs endpoint responds with an error" do
      before do
        stub_request(:get, "https://www.pvta.com/g_trans/google_transit.zip")
          .to_return(status: 500)
      end

      it "does not write anything to the store" do
        call
        expect(internal_store).not_to have_received(:write)
      end
    end
  end

  describe ".gtfs_realtime_alerts" do
    subject(:call) { described_class.gtfs_realtime_alerts }

    before { allow(internal_store).to receive(:read).with("gtfs_realtime_alerts").and_return("cached data") }

    it "returns the cached value for gtfs_realtime_alerts" do
      expect(call).to eq("cached data")
    end
  end

  describe ".refresh_gtfs_realtime_alerts" do
    subject(:call) { described_class.refresh_gtfs_realtime_alerts }

    before do
      allow(CREDENTIALS).to receive(:swiftly_api_key).and_return("test-api-key")
      allow(internal_store).to receive(:write).with("gtfs_realtime_alerts", anything).and_return(nil)
    end

    context "when the swiftly realtime alerts endpoint responds successfully" do
      before do
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-alerts/v2")
          .with(headers: { "Authorization" => "test-api-key" })
          .to_return(body: "server data")
      end

      it "writes the request body to the store" do
        call
        expect(internal_store).to have_received(:write).with("gtfs_realtime_alerts", "server data")
      end
    end

    context "when the swiftly realtime alerts endpoint responds with an error" do
      before do
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-alerts/v2")
          .with(headers: { "Authorization" => "test-api-key" })
          .to_return(status: 500)
      end

      it "does not write anything to the store" do
        call
        expect(internal_store).not_to have_received(:write)
      end
    end
  end

  describe ".gtfs_realtime_trip_updates" do
    subject(:call) { described_class.gtfs_realtime_trip_updates }

    before { allow(internal_store).to receive(:read).with("gtfs_realtime_trip_updates").and_return("cached data") }

    it "returns the cached value for gtfs_realtime_trip_updates" do
      expect(call).to eq("cached data")
    end
  end

  describe ".refresh_gtfs_realtime_trip_updates" do
    subject(:call) { described_class.refresh_gtfs_realtime_trip_updates }

    before do
      allow(CREDENTIALS).to receive(:swiftly_api_key).and_return("test-api-key")
      allow(internal_store).to receive(:write).with("gtfs_realtime_trip_updates", anything).and_return(nil)
    end

    context "when the swiftly realtime trip updates endpoint responds successfully" do
      before do
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates")
          .with(headers: { "Authorization" => "test-api-key" })
          .to_return(body: "server data")
      end

      it "writes the request body to the store" do
        call
        expect(internal_store).to have_received(:write).with("gtfs_realtime_trip_updates", "server data")
      end
    end

    context "when the swiftly realtime trip updates endpoint responds with an error" do
      before do
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates")
          .with(headers: { "Authorization" => "test-api-key" })
          .to_return(status: 500)
      end

      it "does not write anything to the store" do
        call
        expect(internal_store).not_to have_received(:write)
      end
    end
  end
end
