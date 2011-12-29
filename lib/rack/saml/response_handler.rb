module Rack
  class Saml
    require 'rack/saml/response/abstract_response'
    autoload "OneloginResponse", 'rack/saml/response/onelogin_response'
    autoload "OpensamlResponse", 'rack/saml/response/opensaml_response'

    class ResponseHandler
      attr_reader :response

      # Rack::Saml::ResponseHandler
      # request: Rack current request instance
      # saml_config: config/saml.yml 
      # metadata: specified idp entity in the config/metadata.yml
      def initialize(request, saml_config, metadata)
        @response = (eval "Rack::Saml::#{saml_config['assertion_handler'].to_s.capitalize}Response").new(request, saml_config, metadata)
      end

      def extract_attrs(env, attribute_map, opts = {})
        attribute_map.each do |attr_name, env_name|
          attribute = @response.attributes[attr_name]
          env[env_name] = attribute if !attribute.nil?
        end
        if !opts[:shib_app_id].nil?
          env['Shib-Application-ID'] = opts[:shib_app_id]
        end
      end
    end
  end
end
