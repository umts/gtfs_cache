require 'mail'

module GtfsCache
  module ErrorNotifier
    class << self
      def registered(app)
        app.error(StandardError) { raise env['sinatra.error'].tap { |error| notify! error } }
      end

      def notify!(error)
        mail = Mail.new do
          from 'transportation-it@admin.umass.edu'
          to 'bmelz@umass.edu'
          subject 'Error'
          content_type 'text/html; charset=UTF-8'
          body <<~HTML
            <h1>#{error&.class}</h1>
            <pre>#{error&.backtrace&.join("\n")}</pre>
          HTML
        end

        smtp_settings = {
          address: 'localhost',
          port: 1443,
          openssl_verify_mode: 'none'
        }

        # 3. Inject settings and deliver via the explicit instance
        mail.delivery_method :smtp, smtp_settings
        mail.deliver!
      end
    end
  end
end
