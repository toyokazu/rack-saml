# Rack::SAML, a SAML (Shibboleth) SP Rack middleware

[![Gem Version](http://img.shields.io/gem/v/rack-saml.svg)](http://rubygems.org/gems/rack-saml)
[![Build Status](https://travis-ci.org/toyokazu/rack-saml.svg?branch=master)](https://travis-ci.org/toyokazu/rack-saml)

This project is deeply inspired by rack-shibboleth and ruby-saml. It is recommended to use the de facto SAML implementation such as OpenSAML from the security or the functional aspect. However, there are also requirements to use SAML for light weight applications implemented by Ruby. rack-shibboleth may be a candidate to support such kind of objective. However it lacks the configurability to fit OmniAuth and OmniAuth Shibboleth Strategy. It also lacks the upgrade path to the secure and the stable SAML implementation like OpenSAML. So rack-saml is implemented just a prototype Rack middleware. to support SAML (Shibboleth SP).

OmniAuth Shibboleth Strategy
https://github.com/toyokazu/omniauth-shibboleth

rack-saml uses external libraries to generate and validate SAML AuthnRequest/Response. It uses basic Rack functions to implement SAML Transport (HTTP Redirect Binding and HTTP POST Binding).

## Changes

* version 0.0.2: SP session is supported using Rack::Session for Rack applications and ActionDispatch::Session for Rails applications. 
* version 0.1.2: Update to fit newer ruby-saml.

## Limitations

### AuthnRequest Signing and Response Encryption

Current implementation supports only Onelogin SAML assertion handler. It does not support to sign AuthnRequest and encrypt Response. So thus, the assertion encription function should be disabled at IdP side for rack-saml SPs.

## Getting Started

### Setup Gemfile and Installation

    % cd rails-app
    % vi Gemfile
    gem 'rack-saml'
    % bundle install

### Setup Rack::Saml middleware

Rack::Saml uses Rack::Session functions. You have to insert Rack::Session before Rack::Saml middleware. Rack::Session::Cookie is used in the following examples because it is easiest to setup and scale. You can use the other Rack::Session implementation. In a Rails application, it uses ActionDispatch::Session which is compatible with Rack::Session by default. So thus, you do not need to add Rack::Session in the Rails application.

**For Rack applicaitons**

In the following example, config.ru is used to add Rack::Saml middleware into a Rails application.

    % vi config.ru
    use Rack::Session::Cookie, :secret => 'pass_to_auth_session'
    use Rack::Saml, {:config => "#{Rails.root}/config/rack-saml.yml",
                     :metadata => "#{Rails.root}/config/metadata.yml",
                     :attribute_map => "#{Rails.root}/config/attribute-map.yml"}

**For Ralis applications**

In the following example, config/application.rb is used to Rack::Saml middleware into a Rails application.

    % vi config/application.rb
    module TestRackSaml
    class Application < Rails::Application
      config.middleware.use Rack::Saml, {:config => "#{Rails.root}/config/rack-saml.yml",
                                       :metadata => "#{Rails.root}/config/metadata.yml",
                                       :attribute_map => "#{Rails.root}/config/attribute-map.yml"}
    ...

If you like to add this middleware like OmniAuth (add configuration into the config/initializers directory), you can use the following.

    % vi config/initializers/rack_saml.rb
    Rails.application.config.middleware.insert_after Rack::ETag, Rack::Saml,
      {:config => "#{Rails.root}/config/rack-saml.yml",
       :metadata => "#{Rails.root}/config/metadata.yml",
       :attribute_map => "#{Rails.root}/config/attribute-map.yml"}

If you use rack-saml with omniauth-shibboleth, Rack::Saml middleware must be loaded before OmniAuth::Builder. Thus, "insert_after Rack::ETag" is used in the above example.

**Middleware options**

* *:config*: path to rack-saml.yml file
* *:metadata*: path to metadata.yml file
* *:attribute_map*: path to attribute-map.yml file

If you just want to test Rack::Saml, you can ommit middleware options in the both example (config.ru or config/application.rb).

    use Rack::Saml

It may be useful for a tutorial use. At least, saml_idp or shib_ds in rack-saml.yml and metadata.yml must be configured to fit your environment.

Rack::Saml uses default configurations located in the rack-saml gem path.

    $GEM_HOME/rack-saml-x.x.x/config/xxx.yml

Please copy them to an arbitrary directory and edit them if you need. If you want to use your customized configuration file, do not forget to specify the configuration file path by middleware options.

**Configuration files**

You can find default configuration files at

    $GEM_HOME/rack-saml-x.x.x/config/xxx.yml

**rack-saml.yml**

Configuration to set SAML parameters. At least, you must configure saml_idp or shib_ds. They depends on your environments.

* *protected_path*: path name where rack-saml protects, e.g. /auth/shibboleth/callback (default path for OmniAuth Shibboleth Strategy)
* *metadata_path*: the path name where SP's metadata is generated
* *assertion_handler*: 'onelogin' / 'opensaml' (not implemented yet)
* *saml_idp*: IdP's entity ID which is used to authenticate user. This parameter can be omitted when you use Shibboleth Discovery Service (shib_ds).
* *saml_sess_timeout*: SP session timeout (default: 1800 seconds)
* *shib_app_id*: If you want to use the middleware as Shibboleth SP, you should specify an application ID. In the Shibboleth SP default configuration, 'default' is used as the application ID.
* *shib_ds*: If you want to use the middleware as Shibboleth SP and use discovery service, specify the uri of the Discovery Service.
* *saml_sp*: Set the SAML SP's entity ID
* *sp_cert*: path to the SAML SP's certificate file, e.g. cert.pem (AuthnRequest Signing and Response Encryption are not supported yet)
* *sp_key*: path to the SAML SP's key file, e.g. key.pem (AuthnRequest Signing and Response Encryption are not supported yet)
* *allowed_clock_drift*: A clock margin (second) for checking NotBefore condition specified in a SAML Response (default: 0 seconds, 60 second may be good for local test).
* *validation_error*: If set to true, a detailed reason of SAML response validation error will be shown on the browser (true/false)

If not set explicitly, SAML SP's entity ID (saml_sp) is automatically generated from request URI and /rack-saml-sp (fixed path name). The Assertion Consumer Service URI is generated from request URI and protected_path.

    saml_sp_prefix = "#{request.scheme}://#{request.host}#{":#{request.port}" if request.port}#{request.script_name}"
    @config['saml_sp'] ||= "#{saml_sp_prefix}/rack-saml-sp"
    @config['assertion_consumer_service_uri'] = "#{saml_sp_prefix}#{@config['protected_path']}"

**metadata.yml**

To connect to an IdP, you must describe IdP's specification. In rack-saml, it should be written in metadata.yml. metadata.yml file include the following lists. You must generate your own metadata.yml by using conv_metadata.rb.

* *idp_lists*: list of IdP metadata
* *sp_lists*: list of SP metadata

idp_lists and sp_lists are hashes which have entity ids as key values.

parameters of the idp_lists:

* *certificate*: base64 encoded certificate of IdP
* *saml2_http_redirect*: Location attribute of the IdP's assertion handler uri with HTTP Redirect Binding

parameters of the sp_lists (currently not used):

* *certificate*: base64 encoded certificate of SP
* *saml2_http_post*: Location attribute of the SP's assertion consumer uri with HTTP POST Binding

These parameters are automatically extracted from SAML metadata (XML). You can use conv_metadata.rb command for extraction.

    % $GEM_HOME/rack-saml-x.x.x/bin/conv_metadata.rb metadata.xml > metadata.yml

**attribute-map.yml**

attribute-map.yml can extract attributes from SAML Response and put attributes on request environment variables. It is useful to pass attributes into applications. The configuration file format is as follows:

    "Attribute Name": "Environment Variable Name"
    "urn:oid:0.9.2342.19200300.100.1.1": "uid"
    ...

You can use default attribute-map.yml file. If you want to add new attributes, please refer the attribute-map.xml file used in Shibboleth SP.

### Setup IdP to accept rack-saml SP

**SP Metadata generation**

To connect a new SP to the existing IdP, you need to import SP's metadata into the IdP. rack-saml provides metadata generation function. It is generated at '/Shibboleth.sso/Metadata' by default.

**IdP configuration examples not to encrypt assertion**

Current rack-saml implementation does not support assertion encryption because OneLogin::RubySaml does not support AuthnRequest signing and Response encryption. So thus, in the followings, we would like to show sample configurations to disable encryption in IdP assertion processing. These are not recommended for sensitive applications.

**Shibboleth IdP example**

Add the following configuration after <rp:DefaultRelyingParty> in relying-party.xml. You should specify sp entity id at the 'id' and the 'provider' attributes.

    % vi $IDP_HOME/conf/relying-party.xml
    ...
    <rp:RelyingParty id="http://example.com:3000/rack-saml-sp" provider="http://idp.example.com/idp/shibboleth" defaultSigningCredentialRef="IdPCredential">
      <rp:ProfileConfiguration xsi:type="saml:SAML2SSOProfile" includeAttributeStatement="true" assertionLifetime="PT5M" assertionProxyCount="0" signResponses="never" signAssertions="always" encryptAssertions="never" encryptNameIds="never"/>
    </rp:RelyingParty>

## Advanced Topics

### Use with OmniAuth

You can connect rack-saml to omniauth-shibboleth. Basically, you do not need any specific configuration to use with omniauth-shibboleth.

### Use with Devise

You can connect rack-saml to devise by using it together with omniauth and omniauth-shibboleth. The details of how to connect omniauth and devise are described in the following page:

OmniAuth: Overview
https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview

When you use omniauth with devise, the omniauth provider path becomes "/users/auth/shibboleth". So thus, you must set the *protected_path* parameter as "/users/auth/shibboleth/callback". After changing the configuration, you must also re-generate SP Metadata (/Shibboleth.sso/Metadata) and import it to IdP because *<AssertionConsumerService>* parameter in SP Metadata is generated by the *protected_path* parameter.

## TODO

* write spec files
* ruby-opensaml (I hope someone implement it :)

## License (MIT License)

rack-saml is released under the MIT license.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
