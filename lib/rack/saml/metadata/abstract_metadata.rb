module Rack
  class Saml
    class AbstractMetadata
      attr_reader :request, :saml_config, :metadata

      def initialize(request, saml_config, metadata)
        @request = request
        @saml_config = saml_config
        @metadata = metadata
      end

      def generate
      end
    end
  end
end
