require "active_support/testing/time_helpers"
require "gtfs_cache/remote"
require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  shared_examples "a cached remote value" do |remote_key: nil, ttl: nil|
    before do
      freeze_time
      allow(GtfsCache::Remote).to receive_messages(gtfs_schedule: nil,
                                                   gtfs_realtime_alerts: nil,
                                                   gtfs_realtime_trip_updates: nil)
      allow(GtfsCache::Remote).to receive(remote_key).and_return("data 1", "data 2", nil)
    end

    context "when called initially" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when called after an update check with no existing data" do
      before { described_class.check_for_updates }

      it "returns freshly fetched data" do
        expect(subject).to have_attributes(data: "data 1", expires: ttl.from_now)
      end
    end

    context "when called after an update check with fresh data" do
      before do
        described_class.check_for_updates
        travel ttl
        described_class.check_for_updates
      end

      it "returns the still fresh data" do
        expect(subject).to have_attributes(data: "data 1", expires: Time.current)
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
        expect(subject).to have_attributes(data: "data 2", expires: ttl.from_now)
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
        expect(subject).to have_attributes(data: "data 2", expires: 1.second.ago)
      end
    end
  end

  describe ".gtfs_schedule" do
    subject(:call) { described_class.gtfs_schedule }

    it_behaves_like "a cached remote value", remote_key: :gtfs_schedule, ttl: 1.day
  end

  describe ".gtfs_realtime_alerts" do
    subject(:call) { described_class.gtfs_realtime_alerts }

    it_behaves_like "a cached remote value", remote_key: :gtfs_realtime_alerts, ttl: 10.seconds
  end

  describe ".gtfs_realtime_trip_updates" do
    subject(:call) { described_class.gtfs_realtime_trip_updates }

    it_behaves_like "a cached remote value", remote_key: :gtfs_realtime_trip_updates, ttl: 10.seconds
  end
end
