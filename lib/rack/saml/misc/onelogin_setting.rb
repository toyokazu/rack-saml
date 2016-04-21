module Rack
  class Saml
    module OneloginSetting
      require 'ruby-saml'

      def saml_settings
        settings = OneLogin::RubySaml::Settings.new
        settings.assertion_consumer_service_url = @config['assertion_consumer_service_uri']
        settings.issuer = @config['saml_sp']
        settings.certificate = IO::File.open(@config['certificate_path'], "r").read if @config['certificate_path']
        settings.private_key = IO::File.open(@config['private_key_path'], "r").read if @config['private_key_path']
        settings.idp_sso_target_url = @metadata['saml2_http_redirect']
        settings.idp_cert = @metadata['certificate']
        settings.name_identifier_format = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        #settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
        settings
      end
    end
  end
end
