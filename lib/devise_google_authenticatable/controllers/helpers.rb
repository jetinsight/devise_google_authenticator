module DeviseGoogleAuthenticator
  module Controllers # :nodoc:
    module Helpers # :nodoc:
      def google_authenticator_qrcode(user, qualifier=nil, issuer=nil)
        app = user.class.ga_appname || Rails.application.class.parent_name
        data = "otpauth://totp/#{user.email}?secret=#{user.gauth_secret}"
        data << "&issuer=#{app}"
        data = Rack::Utils.escape(data)
        url = "https://chart.googleapis.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{data}"
        return image_tag(url, :alt => 'Google Authenticator QRCode')
      end
    end
  end
end
