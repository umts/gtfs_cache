require "gtfs_cache/store"
require "puma/plugin"

module Puma
  class Plugin
    class GtfsCacheRefresh < Plugin
      def start(_)
        in_background do
          loop do
            GtfsCache::Store.keep_warm
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

Puma::Plugins.register("gtfs_cache_refresh", Puma::Plugin::GtfsCacheRefresh)
