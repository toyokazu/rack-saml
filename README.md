# SAML (Shibboleth SP) middleware for Rack

This project is deeply inspired by rack-shibboleth and ruby-saml. It is recommended to use the defact SAML implementation such as OpenSAML from the security or the functional aspect. However, there also be requirements to use SAML for light weight applications implemented by Ruby. rack-shibboleth may be a candidate to support such kind of objective. However it lacks the configurability to fit OmniAuth and the upgrade path to secure and stable middleware as OpenSAML. So thus I just implemented a prototype to support SAML (Shibboleth SP) for Rack middleware.

https://github.com/intridea/omniauth/wiki

The detail of the authentication middleware Shibboleth is introduced in Shibboleth wiki.

https://wiki.shibboleth.net/

## Limitations

### Signing AuthnRequest

Current implementation supports only Onelogin SAML assertion handler. It does not support to sign AuthnRequest.

### Encrypted Assertion

Current implementation does not support assertion encryption. So thus, assertion encription function should be disabled for rack-saml SPs.

### SP Session

Current implementation does not support keeping session at SP side.

## Getting Started

### Installation

    % gem install rack-saml

### Setup Gemfile

    % cd rails-app
    % vi Gemfile
    gem 'rack-saml'

### Setup Rack::Saml middleware

#### For Rack applicaitons

In the following example, config.ru is used to add Rack::Saml middleware into a Rails application.

    % vi config.ru
    use Rack::Saml, {:saml_config => "#{Rails.root}/config/saml.yml",
                     :metadata => "#{Rails.root}/config/metadata.yml",
                     :attribute_map => "#{Rails.root}/config/attribute-map.yml",
                     :shib_app_id => "default"}

#### For Ralis applications

In the following example, config/application.rb is used to Rack::Saml middleware into a Rails application.

    % vi config/application.rb
    module TestRackSaml
    class Application < Rails::Application
    config.middleware.use Rack::Saml, {:saml_config => "#{Rails.root}/config/saml.yml",
                                       :metadata => "#{Rails.root}/config/metadata.yml",
                                       :attribute_map => "#{Rails.root}/config/attribute-map.yml"
                                       :shib_app_id => "default"}
    ...

If you just want to test Rack::Saml, you can ommit middleware options in the both example (config.ru or config/application.rb).

    use Rack::Saml

However, you can not omit :shib_app_id option if you want to use this middleware with OmniAuth::Shibboleth Strategy.

Rack::Saml uses default configurations located in the rack-saml gem path.

    $GEM_HOME/rack-saml-x.x.x/config/xxx.yml

#### Middleware options

* *:saml_config* path to saml.yml file
* *:metadata* path to metadata.yml file
* *:attribute_map* path to attribute-map.yml file
* *:shib_app_id* If you want to use the middleware as Shibboleth SP, you should specify an application ID. In the Shibboleth SP default configuration, 'default' is used as the application ID.


#### Configuration files

You can find default configuration files at

    $GEM_HOME/rack-saml-x.x.x/config/

##### saml.yml

Configuration to set SAML parameters.

* *protected_path* string or regular expression of the path name where SAML protects, e.g. /auth/shibboleth/callback or '^\/secure\/[^\s]*'
* *protected_path_regexp* use regular expression to match protected_path or not e.g. true / false
* *metadata_path* the path name where SP's metadata is generated
* *assertion_handler* 'onelogin' / 'opensaml' (not implemented yet)
* *saml_idp* idp_entity_id
* *saml_sp* sp_entity_id (self id)
* *sp_cert* path to the SAML SP's certificate file, e.g. cert.pem (signing AuthnRequest is not supported yet)
* *sp_key* path to the SAML SP's key file, e.g. key.pem (signing AuthnRequest is not supported yet)

##### metadata.yml

To connect to an IdP, you must describe IdP's specification. In rack-saml, it should be written in metadata.yml. metadata.yml file include the following lists.

* *idp_lists* list of IdP metadata
* *sp_lists* list of SP metadata

idp_lists and sp_lists are hashes which have entity ids as key values.

parameters of the idp_lists:

* *certificate* base64 encoded certificate of IdP
* *saml2_http_redirect* Location attribute of the IdP's assertion handler uri with HTTP Redirect Binding

parameters of the sp_lists (currently not used):

* *certificate* base64 encoded certificate of SP
* *saml2_http_post* Location attribute of the SP's assertion consumer uri with HTTP POST Binding

These parameters are automatically extracted from SAML metadata. You can use conv_metadata.rb command for extraction.

    % $GEM_HOME/rack-saml-x.x.x/bin/conv_metadata.rb metadata.xml > metadata.yml

##### attribute-map.yml

attribute-map.yml can extract attributes from SAML Response and put attributes on request environment variables. It is useful to pass attributes into applications. The configuration file format is as follows:

    "Attribute Name": "Environment Variable Name"
    "urn:oid:0.9.2342.19200300.100.1.1": "uid"
    ...

### Setup IdP to accept rack-saml SP

#### SP Metadata generation

To connect a new SP to the existing IdP, you need to import SP's metadata into the IdP. rack-saml provides metadata generation function. It is generated at '/Shibboleth.sso/Metadata' by default.

#### IdP configuration examples not to encrypt assertion

Current rack-saml implementation does not support assertion encryption because Onelogin::Saml does not support signature and encryption of assertion. So thus, in the followings, we would like to show sample configurations to disable encryption in IdP assertion processing. These are not recommended for sensitive applications.

##### Shibboleth IdP example

Add the following configuration after <rp:DefaultRelyingParty> in relying-party.xml. You should specify sp entity id at the 'id' and the 'provider' attributes.

    % vi $IDP_HOME/conf/relying-party.xml
    ...
    <rp:RelyingParty id="http://example.com:3000/auth/shibboleth/callback" provider="http://example.com:3000/auth/shibboleth/callback" defaultSigningCredentialRef="IdPCredential">
      <rp:ProfileConfiguration xsi:type="saml:SAML2SSOProfile" includeAttributeStatement="true" assertionLifetime="PT5M" assertionProxyCount="0" signResponses="never" signAssertions="always" encryptAssertions="never" encryptNameIds="never"/>
    </rp:RelyingParty>

## TODO

* ruby-opensaml (I hope someone implement it :)

## License

Copyright (C) 2011 by Toyokazu Akiyama.

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
