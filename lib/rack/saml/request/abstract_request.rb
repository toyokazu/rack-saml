module Rack
  class Saml
    class AbstractRequest
      attr_reader :request, :saml_config, :metadata

      def initialize(request, saml_config, metadata)
        @request = request
        @saml_config = saml_config
        @metadata = metadata
      end

      def redirect_uri
      end
    end
  end
end
