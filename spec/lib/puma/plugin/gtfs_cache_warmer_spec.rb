require "gtfs_cache/store"
require "puma/plugin/gtfs_cache_warmer"

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe Puma::Plugin::GtfsCacheWarmer do
  describe "#start" do
    subject(:call) { plugin.start(nil) }

    let(:plugin) { described_class.new }

    before do
      allow(plugin).to receive(:in_background).and_yield
      allow(plugin).to receive(:sleep) { Thread.stop }
      allow(GtfsCache::Store).to receive(:check_for_updates).and_return(nil)
    end

    def iterate(thread)
      thread.wakeup
      sleep 0.1 until thread.stop?
    end

    it "checks for updates every second" do
      thread = Thread.new { call }
      3.times { iterate(thread) }
      Thread.kill(thread)

      expect(plugin).to have_received(:sleep).thrice.with(1)
      expect(GtfsCache::Store).to have_received(:check_for_updates).thrice
    end

    context "when something fails in the main loop" do
      before { allow(GtfsCache::Store).to receive(:check_for_updates).and_raise(StandardError) }

      it "rescues and carries on" do
        thread = Thread.new { call }
        3.times { iterate(thread) }
        Thread.kill(thread)

        expect(plugin).to have_received(:sleep).thrice.with(1)
        expect(GtfsCache::Store).to have_received(:check_for_updates).thrice
      end
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
