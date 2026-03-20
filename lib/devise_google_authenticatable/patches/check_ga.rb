module DeviseGoogleAuthenticator::Patches
  # patch Sessions controller to check that the OTP is accurate
  module CheckGA
    extend ActiveSupport::Concern
    included do
    # here the patch

      alias_method :create_original, :create

      define_method :checkga_resource_path_name do |resource, id|
        name = resource.class.name.singularize.underscore
        name = name.split('/').last
        "#{name}_checkga_path(id:'#{id}')"
      end

      define_method :create do |&block|

        resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")

        if resource.respond_to?(:get_qr) and resource.gauth_enabled? and resource.require_token?(cookies.signed[:gauth]) #Therefore we can quiz for a QR
          tmpid = resource.assign_tmp #assign a temporary key and fetch it
          user_return_to_path = stored_location_for(:user)  #save the original url that the user was going to before the login interruption
          # Patch to allow login on subdomains
          login_from_product = session[:login_from_product]
          # END: Patch to allow login on subdomains
          warden.logout #log the user out
          store_location_for(:user, user_return_to_path)
          # Patch to allow login on subdomains
          session[:login_from_product] = login_from_product if login_from_product.present?
          # END: Patch to allow login on subdomains

          #we head back into the checkga controller with the temporary id
          #Because the model used for google auth may not always be the same, and may be a sub-model, the eval will evaluate the appropriate path name
          #This change addresses https://github.com/AsteriskLabs/devise_google_authenticator/issues/7
          respond_with resource, :location => eval(checkga_resource_path_name(resource, tmpid))

        else #It's not using, or not enabled for Google 2FA, OR is remembering token and therefore not asking for the moment - carry on, nothing to see here.
          set_flash_message(:notice, :signed_in) if is_flashing_format?
          sign_in(resource_name, resource)
          # Patch to ensure we can reset session properly for a saml login before redirects set
          block.call(resource) if block.present?
          # END: Patch to ensure we can reset session properly for a saml login before redirects set
          respond_with resource, :location => after_sign_in_path_for(resource)
        end

      end
    end
  end
end
