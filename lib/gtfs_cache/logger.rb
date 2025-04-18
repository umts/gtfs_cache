module GtfsCache
  module Logger
    class << self
      def registered(app)
        environment = app.settings.environment
        app.set :access_log, open_log_file!(environment, "access")
        app.set :error_log, open_log_file!(environment, "error")
        app.enable :logging
        app.use Rack::CommonLogger, app.settings.access_log
        app.before { env["rack.errors"] = app.settings.error_log }
      end

      private

      def open_log_file!(env, name)
        log_dir = Pathname(__dir__).join("../../log").expand_path.tap(&:mkpath)
        log_dir.join("#{env}_#{name}.log").open("a+").tap { |file| file.sync = true }
      end
    end
  end
end
