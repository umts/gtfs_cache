require_relative "environment"

if ENV.fetch("RACK_ENV", nil) == "production"
  workers 2
end

plugin :gtfs_cache_refresh
plugin :tmp_restart
