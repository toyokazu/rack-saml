module Rack
  class Saml
    require 'rack/saml/misc/onelogin_setting'

    class OneloginMetadata < AbstractMetadata
      include OneloginSetting

      def initialize(request, config, metadata)
        super(request, config, metadata)
        @sp_metadata = OneLogin::RubySaml::Metadata.new
      end

      def generate
        @sp_metadata.generate(saml_settings)
      end
    end
  end
end
