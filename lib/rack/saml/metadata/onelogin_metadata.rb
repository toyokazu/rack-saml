module Rack
  class Saml
    require 'rack/saml/misc/onelogin_setting'

    class OneloginMetadata < AbstractMetadata
      include OneloginSetting

      def initialize(request, saml_config, metadata)
        super(request, saml_config, metadata)
        @sp_metadata = Onelogin::Saml::Metadata.new
      end

      def generate
        @sp_metadata.generate(saml_settings)
      end
    end
  end
end
