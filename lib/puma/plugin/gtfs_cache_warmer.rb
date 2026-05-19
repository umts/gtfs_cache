require "gtfs_cache/store"
require "puma/plugin"

module Puma
  class Plugin
    class GtfsCacheWarmer < Plugin
      def start(_)
        in_background do
          loop do
            GtfsCache::Store.check_for_updates
          rescue StandardError => e
            e
          ensure
            sleep 1
          end
        end
      end
    end
  end
end

Puma::Plugins.register("gtfs_cache_warmer", Puma::Plugin::GtfsCacheWarmer)
