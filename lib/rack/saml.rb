require 'rack'
require 'yaml'

module Rack
  # Rack::Saml
  #
  # As the Shibboleth SP, Rack::Saml::Base adopts :protected_path
  # as an :assertion_consumer_path. It is easy to configure and
  # support omniauth-shibboleth.
  # To establish single path behavior, it currently supports only
  # HTTP Redirect Binding from SP to Idp
  # HTTP POST Binding from IdP to SP
  class Saml
    autoload "RequestHandler", 'rack/saml/request_handler'
    autoload "MetadataHandler", 'rack/saml/metadata_handler'
    autoload "ResponseHandler", 'rack/saml/response_handler'

    class SamlAssertionError < StandardError
    end

    def default_config_path(config_file)
      ::File.expand_path("../../../config/#{config_file}", __FILE__)
    end

    def default_saml_config
      default_config_path('saml.yml')
    end

    def default_metadata
      default_config_path('metadata.yml')
    end

    def default_attribute_map
      default_config_path('attribute-map.yml')
    end

    def initialize app, opts = {}
      @app = app
      @opts = opts

      if @opts[:saml_config].nil? || !::File.exists?(@opts[:saml_config])
        @opts[:saml_config] = default_saml_config
      end
      @saml_config = YAML.load_file(@opts[:saml_config])
      if @saml_config['assertion_handler'].nil?
        raise ArgumentError, "'assertion_handler' parameter should be specified in the :saml_config file"
      end
      if @opts[:metadata].nil? || !::File.exists?(@opts[:metadata])
        @opts[:metadata] = default_metadata
      end
      @metadata = YAML.load_file(@opts[:metadata])
      if @opts[:attribute_map].nil? || !::File.exists?(@opts[:attribute_map])
        @opts[:attribute_map] = default_attribute_map
      end
      @attribute_map = YAML.load_file(@opts[:attribute_map])
    end

    def call env
      request = Rack::Request.new env
      #return [
      #  403,
      #  {
      #    'Content-Type' => 'text/plain'
      #  },
      #  ["Forbidden." + request.inspect]
      #  ["Forbidden." + env.to_a.map {|i| "#{i[0]}: #{i[1]}"}.join("\n")]
      #]
      if request.request_method == 'GET'
        if match_protected_path?(request) # generate AuthnRequest
          handler = RequestHandler.new(request, @saml_config, @metadata['idp_lists'][@saml_config['saml_idp']])
          return Rack::Response.new.tap { |r|
            r.redirect handler.authn_request.redirect_uri
          }.finish
        elsif match_metadata_path?(request) # generate Metadata
          handler = MetadataHandler.new(request, @saml_config, @metadata['idp_lists'][@saml_config['saml_idp']])
          return [
            200,
            {
              'Content-Type' => 'application/samlmetadata+xml'
            },
            [handler.sp_metadata.generate]
          ]
        end
      elsif request.request_method == 'POST' && match_protected_path?(request) # process Response
        handler = ResponseHandler.new(request, @saml_config, @metadata['idp_lists'][@saml_config['saml_idp']])
        if handler.response.is_valid?
          handler.extract_attrs(env, @attribute_map, @opts)
        else
          raise SamlAssertionError, "Invalid SAML response."
        end
      end

      @app.call env
    end

    def match_protected_path?(request)
      if @saml_config['protected_path_regexp']
        # to be fixed (Regexp)
        return (request.path_info =~ Regexp.new(@saml_config['protected_path']))
      end
      request.path_info == @saml_config['protected_path']
    end

    def match_metadata_path?(request)
      request.path_info == @saml_config['metadata_path']
    end
  end
end
