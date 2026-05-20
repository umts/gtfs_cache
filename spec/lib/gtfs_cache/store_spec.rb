require "active_support/testing/time_helpers"
require "gtfs_cache/remote"
require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  shared_examples "a cached remote value" do |remote_source: nil, ttl: nil|
    let(:remote_responses) { [] }
    let(:stored_datas) { remote_responses }

    before do
      freeze_time
      allow(GtfsCache::Remote).to receive_messages(gtfs_schedule: nil,
                                                   gtfs_realtime_alerts: nil,
                                                   gtfs_realtime_trip_updates: nil)
      allow(GtfsCache::Remote).to receive(remote_source).and_return(*(remote_responses + [nil]))
    end

    context "when called initially" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when called after an update check with no existing data" do
      before { described_class.check_for_updates }

      it "returns freshly fetched data" do
        expect(subject).to have_attributes(data: stored_datas.first, expires: ttl.from_now)
      end
    end

    context "when called after an update check with fresh data" do
      before do
        described_class.check_for_updates
        travel ttl
        described_class.check_for_updates
      end

      it "returns the still fresh data" do
        expect(subject).to have_attributes(data: stored_datas.first, expires: Time.current)
      end
    end

    context "when called after an update check with stale data" do
      before do
        described_class.check_for_updates
        travel ttl
        described_class.check_for_updates
        travel 1.second
        described_class.check_for_updates
      end

      it "returns freshly fetched data" do
        expect(subject).to have_attributes(data: stored_datas.second, expires: ttl.from_now)
      end
    end

    context "when called after an update check with stale data that failed" do
      before do
        described_class.check_for_updates
        travel ttl
        described_class.check_for_updates
        travel 1.second
        described_class.check_for_updates
        travel ttl + 1.second
        described_class.check_for_updates
      end

      it "returns stale data" do
        expect(subject).to have_attributes(data: stored_datas.second, expires: 1.second.ago)
      end
    end
  end

  describe ".gtfs_schedule" do
    subject(:call) { described_class.gtfs_schedule }

    it_behaves_like "a cached remote value", remote_source: :gtfs_schedule, ttl: 1.day do
      let(:remote_responses) { [file_fixture("schedule1.zip").read, file_fixture("schedule2.zip").read] }
    end
  end

  describe ".gtfs_schedule_routes" do
    subject(:call) { described_class.gtfs_schedule_routes }

    it_behaves_like "a cached remote value", remote_source: :gtfs_schedule, ttl: 1.day do
      let(:remote_responses) { [file_fixture("schedule1.zip").read, file_fixture("schedule2.zip").read] }
      let(:stored_datas) { [file_fixture("schedule1/routes.txt").read, file_fixture("schedule2/routes.txt").read] }
    end
  end

  describe ".gtfs_realtime_alerts" do
    subject(:call) { described_class.gtfs_realtime_alerts }

    it_behaves_like "a cached remote value", remote_source: :gtfs_realtime_alerts, ttl: 10.seconds do
      let(:remote_responses) { ["protobuf data 1", "protobuf data 2"] }
    end
  end

  describe ".gtfs_realtime_trip_updates" do
    subject(:call) { described_class.gtfs_realtime_trip_updates }

    it_behaves_like "a cached remote value", remote_source: :gtfs_realtime_trip_updates, ttl: 10.seconds do
      let(:remote_responses) { ["protobuf data 1", "protobuf data 2"] }
    end
  end
end
