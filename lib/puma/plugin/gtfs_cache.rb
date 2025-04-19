require "puma/plugin"

Puma::Plugin.create do
  def start(_)
    in_background { GtfsCache::Cache.periodically_refresh }
  end
end
