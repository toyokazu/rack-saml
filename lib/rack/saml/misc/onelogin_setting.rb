module Rack
  class Saml
    module OneloginSetting
      require 'ruby-saml'

      def saml_settings
        settings = Onelogin::Saml::Settings.new
        settings.assertion_consumer_service_url = "#{@request.scheme}://#{@request.host}#{":#{@request.port}" if @request.port}#{request.script_name}#{@saml_config['protected_path']}"
        settings.issuer = @saml_config['saml_sp']
        settings.idp_sso_target_url = @metadata['saml2_http_redirect']
        settings.idp_cert = @metadata['certificate']
        settings.name_identifier_format = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        #settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
        settings
      end
    end
  end
end
