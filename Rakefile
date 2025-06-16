require_relative "config/environment"

namespace :credentials do
  desc "Outputs the credentials stored in `ARGV[1]` (used by diff helper)"
  task :diff do
    credentials = ActiveSupport::EncryptedConfiguration.new(
      config_path: File.expand_path(ARGV[1], __dir__),
      key_path: CREDENTIALS.key_path,
      env_key: CREDENTIALS.env_key,
      raise_if_missing_key: false
    )
    begin
      puts credentials.read.presence || credentials.content_path.read
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      puts credentials.content_path.read
    end
  end

  desc "Edit the credentials file using the system editor"
  task :edit do
    require "rails/command/helpers/editor"
    include Rails::Command::Helpers::Editor

    using_system_editor { CREDENTIALS.change { |tempfile| system_editor(tempfile) } }
  end

  desc "Show the credentials stored in the credentials file"
  task :show do
    puts CREDENTIALS.read.presence || "No decryptable credentials found"
  end
end
