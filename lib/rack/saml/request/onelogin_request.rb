module Rack
  class Saml
    require 'rack/saml/misc/onelogin_setting'

    class OneloginRequest < AbstractRequest
      include OneloginSetting

      def initialize(request, saml_config, metadata)
        super(request, saml_config, metadata)
        @authrequest = Onelogin::Saml::Authrequest.new
      end

      def redirect_uri
        @authrequest.create(saml_settings)
      end
    end
  end
end
