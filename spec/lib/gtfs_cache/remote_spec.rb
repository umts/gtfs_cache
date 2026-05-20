require "gtfs_cache/remote"

RSpec.describe GtfsCache::Remote do
  shared_examples "an http call that turns errors into nil" do
    let(:headers) { nil }
    let(:body) { nil }

    before do
      stub_request(:get, url).to_return(status:, body:)
                             .tap { |stub| stub.with(headers:) if headers.present? }
    end

    context "when the remote responds successfully" do
      let(:status) { 200 }

      it "returns the response body" do
        expect(subject).to eq(body)
      end
    end

    context "when the remote responds unsuccessfully" do
      let(:status) { 500 }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  shared_context "with swiftly credentials" do
    let(:headers) { { "Authorization" => "test-api-key" } }

    before { allow(CREDENTIALS).to receive(:swiftly_api_key).and_return("test-api-key") }
  end

  describe ".gtfs_schedule" do
    subject { described_class.gtfs_schedule }

    it_behaves_like "an http call that turns errors into nil" do
      let(:url) { "https://www.pvta.com/g_trans/google_transit.zip" }
      let(:body) { file_fixture("schedule1.zip").read }
    end
  end

  describe ".gtfs_realtime_alerts" do
    subject { described_class.gtfs_realtime_alerts }

    it_behaves_like "an http call that turns errors into nil" do
      include_context "with swiftly credentials"

      let(:url) { "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-alerts/v2" }
      let(:body) { "protobuf data" }
    end
  end

  describe ".gtfs_realtime_trip_updates" do
    subject { described_class.gtfs_realtime_trip_updates }

    it_behaves_like "an http call that turns errors into nil" do
      include_context "with swiftly credentials"

      let(:url) { "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates" }
      let(:body) { "protobuf data" }
    end
  end
end
