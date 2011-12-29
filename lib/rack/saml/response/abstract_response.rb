module Rack
  class Saml
    class AbstractResponse
      attr_reader :request, :saml_config, :metadata

      def initialize(request, saml_config, metadata)
        @request = request
        @saml_config = saml_config
        @metadata = metadata
      end

      def is_valid?
      end
    end
  end
end
