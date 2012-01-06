module Rack
  class Saml
    class AbstractRequest
      attr_reader :request, :config, :metadata

      def initialize(request, config, metadata)
        @request = request
        @config = config
        @metadata = metadata
      end

      def redirect_uri
      end
    end
  end
end
