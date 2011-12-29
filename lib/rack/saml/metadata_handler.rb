module Rack
  class Saml
    require 'rack/saml/metadata/abstract_metadata'
    autoload "OneloginMetadata", 'rack/saml/metadata/onelogin_metadata'
    autoload "OpensamlMetadata", 'rack/saml/metadata/opensaml_metadata'

    class MetadataHandler
      attr_reader :sp_metadata

      # Rack::Saml::MetadataHandler
      # request: Rack current request instance
      # saml_config: config/saml.yml 
      # metadata: specified idp entity in the config/metadata.yml
      def initialize(request, saml_config, metadata)
        @sp_metadata = (eval "Rack::Saml::#{saml_config['assertion_handler'].to_s.capitalize}Metadata").new(request, saml_config, metadata)
      end
    end
  end
end
