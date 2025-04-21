require "gtfs_cache/store"
require "puma/plugin/gtfs_cache_refresh"

# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
RSpec.describe Puma::Plugin::GtfsCacheRefresh do
  describe "#start" do
    subject(:call) { plugin.start(nil) }

    let(:plugin) { described_class.new }

    around { |example| Timecop.freeze { example.run } }

    before do
      allow(GtfsCache::Store).to receive_messages(refresh_gtfs: nil,
                                                  refresh_gtfs_realtime_alerts: nil,
                                                  refresh_gtfs_realtime_trip_updates: nil)
      allow(plugin).to receive(:in_background).and_yield
      allow(plugin).to(receive(:sleep)) { Thread.stop }
    end

    it "fetches remote data immediately" do
      thread = Thread.new { plugin.start(nil) }
      sleep 0.1 until thread.stop?
      Thread.kill(thread)

      expect(GtfsCache::Store).to have_received(:refresh_gtfs).once
      expect(GtfsCache::Store).to have_received(:refresh_gtfs_realtime_alerts).once
      expect(GtfsCache::Store).to have_received(:refresh_gtfs).once
    end

    it "fetches gtfs data every day" do
      thread = Thread.new { plugin.start(nil) }
      4.times do
        sleep 0.1 until thread.stop?
        Timecop.freeze(12.hours.from_now)
        thread.wakeup
      end
      sleep 0.1 until thread.stop?
      Thread.kill(thread)

      expect(GtfsCache::Store).to have_received(:refresh_gtfs).thrice
    end

    it "fetches gtfs realtime data every ten seconds" do
      thread = Thread.new { plugin.start(nil) }
      4.times do
        sleep 0.1 until thread.stop?
        Timecop.freeze(5.seconds.from_now)
        thread.wakeup
      end
      sleep 0.1 until thread.stop?
      Thread.kill(thread)

      expect(GtfsCache::Store).to have_received(:refresh_gtfs_realtime_alerts).thrice
      expect(GtfsCache::Store).to have_received(:refresh_gtfs_realtime_trip_updates).thrice
    end

    context "when something fails in the main loop" do
      before { allow(GtfsCache::Store).to receive(:refresh_gtfs).and_raise(StandardError) }

      it "rescues and carries on" do
        thread = Thread.new { plugin.start(nil) }
        sleep 0.1 until thread.stop?
        Timecop.freeze(1.day.from_now)
        thread.wakeup
        sleep 0.1 until thread.stop?
        Thread.kill(thread)

        expect(GtfsCache::Store).to have_received(:refresh_gtfs).twice
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
