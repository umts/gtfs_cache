require "active_support/testing/time_helpers"
require "gtfs_cache/remote"
require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  shared_examples "a cached value reader" do |key: nil|
    context "when there is no data in the cache" do
      before { redis.set("#{key}:etag", "unused") }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there is data but no control information in the cache" do
      before { redis.set("#{key}:data", "cached data") }

      it "returns the data with control information missing" do
        expect(subject).to have_attributes(data: "cached data", etag: nil, time: nil, expires: nil)
      end
    end

    context "when there is data and control information in the cache" do
      before do
        freeze_time
        redis.set("#{key}:data", "cached data")
        redis.set("#{key}:etag", "etag")
        redis.set("#{key}:time", Time.current.to_i)
        redis.set("#{key}:expires", 10.seconds.from_now.to_i)
      end

      it "returns the data and parsed control information" do
        expect(subject).to have_attributes(
          data: "cached data", etag: "etag", time: Time.current, expires: 10.seconds.from_now
        )
      end
    end
  end

  shared_examples "a cached value writer" do |key: nil, ttl: nil|
    def cache_keys = ["#{key}:data", "#{key}:etag", "#{key}:time", "#{key}:expires"]

    def new_values = redis.mget(*cache_keys)

    let(:data) { response_body }

    before do
      freeze_time
      stub_request(:get, request_url)
        .tap { |stub| stub.with(headers: request_headers) if defined?(request_headers) }
        .to_return(status: response_status, body: response_body)
      redis.mset(*cache_keys.zip(old_values).flatten)
    end

    context "when nothing is cached" do
      let(:old_values) { [nil, nil, nil, nil] }
      let(:response_status) { 200 }

      it "updates the cache" do
        subject
        expect(new_values).to eq([data,
                                  Digest::MD5.hexdigest(data),
                                  Time.current.to_i.to_s,
                                  ttl.after(Time.current).to_i.to_s])
      end
    end

    context "when fresh data is cached" do
      let(:old_values) { ["old data", "etag", 1.day.ago.to_i, Time.current.to_i] }
      let(:response_status) { 200 }

      it "does not update the cache" do
        subject
        expect(new_values).to eq(old_values)
      end
    end

    context "when stale data is cached" do
      let(:old_values) { ["old data", "etag", 1.day.ago.to_i, 1.second.ago.to_i] }
      let(:response_status) { 200 }

      it "updates the cache" do
        subject
        expect(new_values).to eq([data,
                                  Digest::MD5.hexdigest(data),
                                  Time.current.to_i.to_s,
                                  ttl.after(Time.current).to_i.to_s])
      end
    end

    context "when stale data is cached and the remote responds with an error" do
      let(:old_values) { ["old data", "etag", 1.day.ago.to_i, 1.second.ago.to_i] }
      let(:response_status) { 500 }

      it "does not update the cache" do
        subject
        expect(new_values).to eq(old_values)
      end
    end
  end

  describe ".gtfs_schedule" do
    subject { described_class.gtfs_schedule }

    it_behaves_like "a cached value reader", key: "gtfs_schedule"
  end

  describe ".gtfs_schedule_routes" do
    subject { described_class.gtfs_schedule_routes }

    it_behaves_like "a cached value reader", key: "gtfs_schedule_routes"
  end

  describe ".gtfs_realtime_alerts" do
    subject { described_class.gtfs_realtime_alerts }

    it_behaves_like "a cached value reader", key: "gtfs_realtime_alerts"
  end

  describe ".gtfs_realtime_trip_updates" do
    subject { described_class.gtfs_realtime_trip_updates }

    it_behaves_like "a cached value reader", key: "gtfs_realtime_trip_updates"
  end

  describe ".check_for_updates" do
    subject { described_class.check_for_updates }

    it_behaves_like "a cached value writer", key: "gtfs_schedule", ttl: 1.day do
      let(:request_url) { "https://www.pvta.com/g_trans/google_transit.zip" }
      let(:request_headers) { nil }
      let(:response_body) { file_fixture("schedule1.zip").read }
    end
  end
end
