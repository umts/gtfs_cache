require_relative "environment"

if ENV.fetch("RACK_ENV", nil) == "production"
  workers 2
  threads 2, 5
  preload_app!
end

plugin :gtfs_cache_warmer
plugin :tmp_restart
