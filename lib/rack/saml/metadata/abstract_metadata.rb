module Rack
  class Saml
    class AbstractMetadata
      attr_reader :request, :config, :metadata

      def initialize(request, config, metadata)
        @request = request
        @config = config
        @metadata = metadata
      end

      def generate
      end
    end
  end
end
