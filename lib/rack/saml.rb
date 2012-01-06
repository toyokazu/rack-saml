require 'rack'
require 'yaml'
require 'securerandom'

module Rack
  # Rack::Saml
  #
  # As the Shibboleth SP, Rack::Saml::Base adopts :protected_path
  # as an :assertion_consumer_path. It is easy to configure and
  # support omniauth-shibboleth.
  # To establish single path behavior, it currently supports only
  # HTTP Redirect Binding from SP to Idp
  # HTTP POST Binding from IdP to SP
  #
  # rack-saml uses rack.session to store SAML and Discovery Service
  # status.
  # env['rack.session'] = {
  #   'rack_saml' => {
  #     'ds.session' => {
  #       'sid' => temporally_generated_hash,
  #       'expire_at' => xxxxx # timestamp
  #     }
  #     'saml_authreq.session' => {
  #       'sid' => temporally_generated_hash,
  #       'expire_at' => xxxxx # timestamp
  #     }
  #     'saml_res.session' => {
  #       'sid' => temporally_generated_hash,
  #       'expire_at' => xxxxx # timestamp,
  #       'env' => {}
  #     }
  #   }
  # }
  class Saml
    autoload "RequestHandler", 'rack/saml/request_handler'
    autoload "MetadataHandler", 'rack/saml/metadata_handler'
    autoload "ResponseHandler", 'rack/saml/response_handler'

    def default_config_path(config_file)
      ::File.expand_path("../../../config/#{config_file}", __FILE__)
    end

    def default_config
      default_config_path('rack-saml.yml')
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

      if @opts[:config].nil? || !::File.exists?(@opts[:config])
        @opts[:config] = default_config
      end
      @config = YAML.load_file(@opts[:config])
      if @config['assertion_handler'].nil?
        raise ArgumentError, "'assertion_handler' parameter should be specified in the :config file"
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

    class Session
      RACK_SAML_COOKIE = '_rack_saml'
      def initialize(env)
        @rack_session = env['rack.session']
        if @rack_session[RACK_SAML_COOKIE].nil?
          @session = @rack_session[RACK_SAML_COOKIE] = {
            'ds.session' => {},
            'saml_authreq.session' => {},
            'saml_res.session' => {'env' => {}}
          }
        else
          @session = @rack_session[RACK_SAML_COOKIE]
        end
      end

      def generate_sid(length = 32)
        SecureRandom.hex(length)
      end

      def get_sid(type)
        @session["#{type}.session"]['sid']
      end

      def start(type, timeout = 300)
        sid = nil
        if timeout.nil?
          period = nil
        else
          period = Time.now + timeout
        end
        case type
        when 'ds'
          sid = generate_sid(4)
        when 'saml_authreq' 
          sid = generate_sid
        when 'saml_res'
          sid = generate_sid
        end
        @session["#{type}.session"]['sid'] = sid
        @session["#{type}.session"]['expired_at'] = period
        @session["#{type}.session"]
      end

      def finish(type)
        @session["#{type}.session"] = {}
      end

      def env
        @session['saml_res.session']['env']
      end

      def is_valid?(type, sid = nil)
        session = @session["#{type}.session"]
        return false if session['sid'].nil? # no valid session
        if session['expired_at'].nil? # no expiration
          return true if sid.nil? # no sid check
          return true if session['sid'] == sid # sid check
        else
          if Time.now < Time.at(session['expired_at']) # before expiration
            return true if sid.nil? # no sid check
            return true if session['sid'] == sid # sid check
          end
        end
        false
      end
    end

    def call env
      session = Session.new(env)
      request = Rack::Request.new env
      # saml_sp: SAML SP's entity_id
      # generate saml_sp from request uri and default path (rack-saml-sp)
      saml_sp_prefix = "#{request.scheme}://#{request.host}#{":#{request.port}" if request.port}#{request.script_name}"
      @config['saml_sp'] = "#{saml_sp_prefix}/rack-saml-sp"
      @config['assertion_consumer_service_uri'] = "#{saml_sp_prefix}#{@config['protected_path']}"
      # for debug
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
          if session.is_valid?('saml_res') # the client already has a valid session
            ResponseHandler.extract_attrs(request, session)
          else
            if !@config['shib_ds'].nil? # use discovery service (ds)
              if request.params['entityID'].nil? # start ds session
                session.start('ds')
                return Rack::Response.new.tap { |r|
                  r.redirect "#{@config['shib_ds']}?entityID=#{URI.encode(@config['saml_sp'], /[^\w]/)}&return=#{URI.encode("#{@config['assertion_consumer_service_uri']}?target=#{session.get_sid('ds')}", /[^\w]/)}"
                }.finish
              end
              if !session.is_valid?('ds', request.params['target']) # confirm ds session
                current_sid = session.get_sid('ds')
                session.finish('ds')
                return create_response(500, 'text/html', "Internal Server Error: Invalid discovery service session current sid=#{current_sid}, request sid=#{request.params['target']}")
              end
              session.finish('ds')
              @config['saml_idp'] = request.params['entityID']
            end
            session.start('saml_authreq')
            handler = RequestHandler.new(request, @config, @metadata['idp_lists'][@config['saml_idp']])
            return Rack::Response.new.tap { |r|
              r.redirect handler.authn_request.redirect_uri
            }.finish
          end
        elsif match_metadata_path?(request) # generate Metadata
          handler = MetadataHandler.new(request, @config, @metadata['idp_lists'][@config['saml_idp']])
          return create_response(200, 'application/samlmetadata+xml', handler.sp_metadata.generate)
        end
      elsif request.request_method == 'POST' && match_protected_path?(request) # process Response
        if session.is_valid?('saml_authreq')
          handler = ResponseHandler.new(request, @config, @metadata['idp_lists'][@config['saml_idp']])
          if handler.response.is_valid?
            session.finish('saml_authreq')
            session.start('saml_res', @config['saml_sess_timeout'] || 1800)
            handler.extract_attrs(env, session, @attribute_map)
          else
            return create_response(403, 'text/html', 'SAML Error: Invalid SAML response.')
          end
        else
          return create_response(500, 'text/html', 'No valid AuthnRequest session.')
        end
      end

      @app.call env
    end

    def match_protected_path?(request)
      request.path_info == @config['protected_path']
    end

    def match_metadata_path?(request)
      request.path_info == @config['metadata_path']
    end

    def create_response(code, content_type, message)
      return [
        code,
        {
          'Content-Type' => content_type
        },
        [message]
      ]
    end
  end
end
