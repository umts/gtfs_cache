require "active_support/testing/time_helpers"
require "gtfs_cache/remote"
require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  shared_examples "a cache entry" do |key: nil|
    context "when there is no data in redis" do
      before { redis.set("#{key}:expires", "not valid") }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there is data but no control info in redis" do
      before { redis.set("#{key}:data", "cached data") }

      it "returns the data without control information" do
        expect(subject).to have_attributes(data: "cached data", expires: nil)
      end
    end

    context "when there is data and control information in the cache" do
      before do
        freeze_time
        redis.set("#{key}:data", "cached data")
        redis.set("#{key}:expires", 10.seconds.from_now.to_i)
      end

      it "returns the data with parsed control information" do
        expect(subject).to have_attributes(data: "cached data", expires: 10.seconds.from_now)
      end
    end
  end

  describe ".gtfs_schedule" do
    subject { described_class.gtfs_schedule }

    it_behaves_like "a cache entry", key: "gtfs_schedule"
  end

  describe ".gtfs_schedule_routes" do
    subject { described_class.gtfs_schedule_routes }

    it_behaves_like "a cache entry", key: "gtfs_schedule_routes"
  end

  describe ".gtfs_realtime_alerts" do
    subject { described_class.gtfs_realtime_alerts }

    it_behaves_like "a cache entry", key: "gtfs_realtime_alerts"
  end

  describe ".gtfs_realtime_trip_updates" do
    subject { described_class.gtfs_realtime_trip_updates }

    it_behaves_like "a cache entry", key: "gtfs_realtime_trip_updates"
  end
end
