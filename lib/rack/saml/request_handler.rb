module Rack
  class Saml
    require 'rack/saml/request/abstract_request'
    autoload "OneloginRequest", 'rack/saml/request/onelogin_request'
    autoload "OpensamlRequest", 'rack/saml/request/opensaml_request'

    class RequestHandler
      attr_reader :authn_request 

      # Rack::Saml::RequestHandler
      # request: Rack current request instance
      # config: config/saml.yml 
      # metadata: specified idp entity in the config/metadata.yml
      def initialize(request, config, metadata)
        @authn_request = (eval "Rack::Saml::#{config['assertion_handler'].to_s.capitalize}Request").new(request, config, metadata)
      end
    end
  end
end
