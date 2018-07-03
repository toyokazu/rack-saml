module Rack
  class Saml
    module OneloginSetting
      require 'ruby-saml'

      def saml_settings
        settings = OneLogin::RubySaml::Settings.new
        settings.assertion_consumer_service_url = @config['assertion_consumer_service_uri']
        settings.issuer = @config['saml_sp']
        if ENV['SP_CERT']
          settings.certificate = ENV['SP_CERT']
        elsif @config['sp_cert']
          settings.certificate = ::File.open(@config['sp_cert'], 'r').read
        end
        if ENV['SP_KEY']
          settings.private_key = ENV['SP_KEY']
        elsif @config['sp_key']
          settings.private_key = ::File.open(@config['sp_key'], 'r').read
        end
        settings.idp_sso_target_url = @metadata['saml2_http_redirect']
        settings.idp_cert = @metadata['certificate']
        settings.name_identifier_format = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
        #settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
        settings
      end
    end
  end
end
