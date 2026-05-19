$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bundler/setup"
Bundler.require(:default, ENV.fetch("RACK_ENV", "development"))
require_relative "credentials"
