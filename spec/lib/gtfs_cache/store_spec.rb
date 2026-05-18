require "active_support/testing/time_helpers"
require "gtfs_cache/remote"
require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  before do
    freeze_time
    allow(GtfsCache::Remote).to receive_messages(gtfs_schedule: nil,
                                                 gtfs_realtime_alerts: nil,
                                                 gtfs_realtime_trip_updates: nil)
  end

  describe ".gtfs_schedule" do
    subject(:call) { described_class.gtfs_schedule }

    before { allow(GtfsCache::Remote).to receive(:gtfs_schedule).and_return("data 1", "data 2", nil) }

    context "without checking for updates" do
      it "returns nil" do
        expect(call).to be_nil
      end
    end

    context "when initial data has been fetched" do
      before { described_class.check_for_updates }

      it "returns the stored data" do
        expect(call).to eq("data 1")
      end
    end

    context "when updates have been checked less than 1 day after the last" do
      before do
        described_class.check_for_updates
        travel 23.hours + 59.minutes + 59.seconds
        described_class.check_for_updates
      end

      it "returns the initial stored data" do
        expect(call).to eq("data 1")
      end
    end

    context "when updates have been checked more than 1 day after the last" do
      before do
        described_class.check_for_updates
        travel 23.hours + 59.minutes + 59.seconds
        described_class.check_for_updates
        travel 1.minute
        described_class.check_for_updates
      end

      it "returns refreshed data" do
        expect(call).to eq("data 2")
      end
    end

    context "when we have stale data but didnt get anything back from the remote" do
      before do
        described_class.check_for_updates
        travel 23.hours + 59.minutes + 59.seconds
        described_class.check_for_updates
        travel 1.minute
        described_class.check_for_updates
        travel 24.hours
        described_class.check_for_updates
      end

      it "returns stale data" do
        expect(call).to eq("data 2")
      end
    end
  end

  describe ".gtfs_realtime_alerts" do
    subject(:call) { described_class.gtfs_realtime_alerts }

    context "when the store is empty" do
      it "returns nil" do
        expect(call).to be_nil
      end
    end

    context "when the store has data" do
      before do
        allow(GtfsCache::Remote).to receive(:gtfs_realtime_alerts).and_return("stored data")
        described_class.check_for_updates
      end

      it "returns the stored data" do
        expect(call).to eq("stored data")
      end
    end
  end

  describe ".gtfs_realtime_trip_updates" do
    subject(:call) { described_class.gtfs_realtime_trip_updates }

    context "when the store is empty" do
      it "returns nil" do
        expect(call).to be_nil
      end
    end

    context "when the store has data" do
      before do
        allow(GtfsCache::Remote).to receive(:gtfs_realtime_trip_updates).and_return("stored data")
        described_class.check_for_updates
      end

      it "returns the stored data" do
        expect(call).to eq("stored data")
      end
    end
  end
end
