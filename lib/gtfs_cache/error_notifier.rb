# simplecov:disable
module GtfsCache
  class ErrorNotifier
    IGNORED = [Sinatra::NotFound].freeze
    TEMPLATE = File.read(File.expand_path("error_template.txt", __dir__)).freeze

    def initialize(app) = @app = app

    def call(env)
      @app.call(env).tap do
        env["sinatra.error"]&.then { |error| self.class.notify!(error) }
      end
    end

    class << self
      def notify!(error)
        return if IGNORED.any? { error.is_a?(it) }
        return unless ENV.fetch("RACK_ENV", nil) == "production"

        mail(error).deliver!
      end

      private

      def mail(error)
        content = render(error)
        mail = Mail.new do
          from "transportation-it@admin.umass.edu"
          to "programmers@admin.umass.edu"
          subject "#{error.class} from gtfs-cache"
          content_type "text/html; charset=UTF-8"
          body content
        end
        mail.delivery_method :smtp, address: "mailhub.oit.umass.edu", port: 25, openssl_verify_mode: "none"
        mail
      end

      def render(error)
        format TEMPLATE, class: error.class, backtrace: error.backtrace&.join("\n") || "No backtrace given"
      end
    end
  end
end
# simplecov:enable
