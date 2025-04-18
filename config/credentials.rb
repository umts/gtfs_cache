require "active_support/encrypted_configuration"

CREDENTIALS = ActiveSupport::EncryptedConfiguration.new(
  config_path: File.expand_path("gtfs_cache.yml.enc", __dir__),
  key_path: File.expand_path("gtfs_cache.key", __dir__),
  env_key: "MASTER_KEY",
  raise_if_missing_key: false
)
