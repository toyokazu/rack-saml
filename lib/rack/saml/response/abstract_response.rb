module Rack
  class Saml
    class AbstractResponse
      attr_reader :request, :config, :metadata

      def initialize(request, config, metadata)
        @request = request
        @config = config
        @metadata = metadata
      end

      def is_valid?
      end
    end
  end
end
