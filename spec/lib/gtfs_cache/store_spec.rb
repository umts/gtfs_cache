require "active_support/testing/time_helpers"
require "gtfs_cache/remote"
require "gtfs_cache/store"

RSpec.describe GtfsCache::Store do
  include ActiveSupport::Testing::TimeHelpers

  shared_examples "it reads from the cache" do |key: nil|
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

  shared_examples "it writes to the cache" do |key: nil, ttl: nil|
    let(:local_data) { remote_data }

    before { freeze_time }

    context "when the remote responds successfully" do
      before { request_stub.to_return(status: 200, body: remote_data) }

      context "with nothing in the cache" do
        it "caches the remote data with control information" do
          subject
          expect(redis.mget("#{key}:data", "#{key}:expires")).to eq([local_data, ttl.from_now.to_i.to_s])
        end
      end

      context "with incomplete data in the cache" do
        before { redis.set("#{key}:expires", Time.current.to_i) }

        it "caches the remote data with control information" do
          subject
          expect(redis.mget("#{key}:data", "#{key}:expires")).to eq([local_data, ttl.from_now.to_i.to_s])
        end
      end

      context "with stale data in the cache" do
        before { redis.mset("#{key}:data", "stale data", "#{key}:expires", 1.second.ago.to_i) }

        it "caches the remote data with control information" do
          subject
          expect(redis.mget("#{key}:data", "#{key}:expires")).to eq([local_data, ttl.from_now.to_i.to_s])
        end
      end

      context "with fresh data in the cache" do
        before { redis.mset("#{key}:data", "fresh data", "#{key}:expires", Time.current.to_i) }

        it "keeps the fresh data" do
          subject
          expect(redis.mget("#{key}:data", "#{key}:expires")).to eq(["fresh data", Time.current.to_i.to_s])
        end
      end
    end

    context "when the remote responds with an error" do
      before { request_stub.to_return(status: 500) }

      context "with nothing in the cache" do
        it "does nothing and does not raise an error" do
          subject
          expect(redis.mget("#{key}:data", "#{key}:expires")).to all(be_nil)
        end
      end

      context "with stale data" do
        before { redis.mset("#{key}:data", "some data", "#{key}:expires", 1.second.ago.to_i) }

        it "keeps the stale data around" do
          subject
          expect(redis.mget("#{key}:data", "#{key}:expires")).to eq(["some data", 1.second.ago.to_i.to_s])
        end
      end
    end
  end

  describe ".gtfs_schedule" do
    subject { described_class.gtfs_schedule }

    it_behaves_like "it reads from the cache", key: "gtfs_schedule"
  end

  describe ".gtfs_schedule_routes" do
    subject { described_class.gtfs_schedule_routes }

    it_behaves_like "it reads from the cache", key: "gtfs_schedule_routes"
  end

  describe ".gtfs_realtime_alerts" do
    subject { described_class.gtfs_realtime_alerts }

    it_behaves_like "it reads from the cache", key: "gtfs_realtime_alerts"
  end

  describe ".gtfs_realtime_trip_updates" do
    subject { described_class.gtfs_realtime_trip_updates }

    it_behaves_like "it reads from the cache", key: "gtfs_realtime_trip_updates"
  end

  describe ".check_for_updates" do
    subject(:call) { described_class.check_for_updates }

    before do
      allow(CREDENTIALS).to receive(:swiftly_api_key).and_return("test-swiftly-api-key")
      stub_request(:get, /.*/).to_return(status: 404)
    end

    it_behaves_like "it writes to the cache", key: "gtfs_schedule", ttl: 1.day do
      let(:request_stub) { stub_request(:get, "https://www.pvta.com/g_trans/google_transit.zip") }
      let(:remote_data) { file_fixture("schedule1.zip").read }
    end

    it_behaves_like "it writes to the cache", key: "gtfs_schedule_routes", ttl: 1.day do
      let(:request_stub) { stub_request(:get, "https://www.pvta.com/g_trans/google_transit.zip") }
      let(:remote_data) { file_fixture("schedule1.zip").read }
      let(:local_data) { file_fixture("schedule1/routes.txt").read }
    end

    it_behaves_like "it writes to the cache", key: "gtfs_realtime_alerts", ttl: 10.seconds do
      let(:request_stub) do
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-alerts/v2")
          .with(headers: { "Authorization" => "test-swiftly-api-key" })
      end
      let(:remote_data) { "protobuf data" }
    end

    it_behaves_like "it writes to the cache", key: "gtfs_realtime_trip_updates", ttl: 10.seconds do
      let(:request_stub) do
        stub_request(:get, "https://api.goswift.ly/real-time/pioneer-valley-pvta/gtfs-rt-trip-updates")
          .with(headers: { "Authorization" => "test-swiftly-api-key" })
      end
      let(:remote_data) { "protobuf data" }
    end

    context "when everything is fresh" do
      before do
        redis.mset "gtfs_schedule:data", "fresh", "gtfs_schedule:expires", Time.current.to_i,
                   "gtfs_schedule_routes:data", "fresh", "gtfs_schedule_routes:expires", Time.current.to_i,
                   "gtfs_realtime_alerts:data", "fresh", "gtfs_realtime_alerts:expires", Time.current.to_i,
                   "gtfs_realtime_trip_updates:data", "fresh", "gtfs_realtime_trip_updates:expires", Time.current.to_i
      end

      it "does not make any requests" do
        call
        expect(a_request(:get, /.*/)).not_to have_been_requested
      end
    end
  end
end
