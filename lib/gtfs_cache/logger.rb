module GtfsCache
  module Logger
    class << self
      def registered(app)
        log_file = open_log_file!(app.settings.environment)
        app.enable :logging
        app.before { env["rack.errors"] = log_file }
      end

      private

      def open_log_file!(env)
        log_dir = Pathname(__dir__).join("../../log").expand_path.tap(&:mkpath)
        log_dir.join("#{env}.log").open("a+").tap { |file| file.sync = true }
      end
    end
  end
end
