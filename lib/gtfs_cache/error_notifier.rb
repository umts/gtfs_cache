require 'mail'

module GtfsCache
  class ErrorNotifier
    def initialize(app) = @app = app

    def call(env)
      @app.call(env).tap do
        env['sinatra.error']&.then { |error| self.class.notify!(error) }
      end
    end

    class << self
      def notify!(error)
        mail = Mail.new do
          from 'transportation-it@admin.umass.edu'
          to 'bmelz@umass.edu'
          subject "gtfs-cache error (#{error.class})"
          content_type 'text/html; charset=UTF-8'
          body <<~HTML
            <html lang="en" xmlns:o="urn:schemas-microsoft-com:office:office">
              <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <meta name="color-scheme" content="light dark">
                <meta name="supported-color-schemes" content="light dark">
                <style>
                  :root {
                    color-scheme: light dark;
                    supported-color-schemes: light dark;
                  }
                </style>
                <!--[if mso]>
                  <xml>
                    <o:OfficeDocumentSettings>
                      <o:PixelsPerInch>96</o:PixelsPerInch>
                    </o:OfficeDocumentSettings>
                  </xml>
                <![endif]-->
              </head>
              <body style="margin: 0; padding: 0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%;">
                <table width="100%" border="0" cellspacing="0" cellpadding="0" style="border-collapse: collapse;">
                  <tr>
                    <td align="center">
                      <!--[if mso]>
                        <table width="700" border="0" cellspacing="0" cellpadding="0" align="center" style="width: 700px;"><tr><td>
                      <![endif]-->
                      <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 700px; width: 100%; margin: 0 auto; text-align: left; font-size: 14px; font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;">
                        <tr>
                          <td bgcolor="#fefefe" style="padding: 60px 30px; background-color: #fefefe; color: #010101; font-size: 14px; font-family: Arial, Helvetica, sans-serif;">
                            <h1>#{error.class}</h1>
                            <pre>#{error.backtrace.join("\n")}</pre>
                          </td>
                        </tr>
                      </table>
                      <!--[if mso]>
                        </td></tr></table>
                      <![endif]-->
                    </td>
                  </tr>
                </table>
              </body>
            </html>
          HTML
        end
        mail.delivery_method :smtp, address: 'localhost', port: 1443, openssl_verify_mode: 'none'
        mail.deliver!
      end
    end
  end
end
