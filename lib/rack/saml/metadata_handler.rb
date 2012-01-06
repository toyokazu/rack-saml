module Rack
  class Saml
    require 'rack/saml/metadata/abstract_metadata'
    autoload "OneloginMetadata", 'rack/saml/metadata/onelogin_metadata'
    autoload "OpensamlMetadata", 'rack/saml/metadata/opensaml_metadata'

    class MetadataHandler
      attr_reader :sp_metadata

      # Rack::Saml::MetadataHandler
      # request: Rack current request instance
      # config: config/rack-saml.yml 
      # metadata: specified idp entity in the config/metadata.yml
      def initialize(request, config, metadata)
        @sp_metadata = (eval "Rack::Saml::#{config['assertion_handler'].to_s.capitalize}Metadata").new(request, config, metadata)
      end
    end
  end
end
