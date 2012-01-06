module Rack
  class Saml
    require 'rack/saml/response/abstract_response'
    autoload "OneloginResponse", 'rack/saml/response/onelogin_response'
    autoload "OpensamlResponse", 'rack/saml/response/opensaml_response'

    class ResponseHandler
      attr_reader :response

      # Rack::Saml::ResponseHandler
      # request: Rack current request instance
      # config: config/saml.yml 
      # metadata: specified idp entity in the config/metadata.yml
      def initialize(request, config, metadata)
        @response = (eval "Rack::Saml::#{config['assertion_handler'].to_s.capitalize}Response").new(request, config, metadata)
      end

      def extract_attrs(env, session, attribute_map)
        if session.env.empty?
          attribute_map.each do |attr_name, env_name|
            attribute = @response.attributes[attr_name]
            if !attribute.nil?
              session.env[env_name] = attribute
            end
          end
          if !@response.config['shib_app_id'].nil?
            session.env['Shib-Application-ID'] = @response.config['shib_app_id']
            session.env['Shib-Session-ID'] = session.get_sid('saml_res')
          end
        end
        session.env.each do |k, v|
          env[k] = v
        end
      end

      def self.extract_attrs(env, session)
        session.env.each do |k, v|
          env[k] = v
        end
      end
    end
  end
end
