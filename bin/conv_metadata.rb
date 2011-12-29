#!/usr/bin/env ruby
require 'rexml/document'
require 'uri'
require 'yaml'

DS = 'http://www.w3.org/2000/09/xmldsig#'

if ARGV.size < 1
  puts "outputs yaml format metadata file"
  puts "usage: conv_metadata.rb metadata_file"
  exit(1)
end

file = File.new(ARGV[0])
doc = REXML::Document.new(file)

def get_list_type(elem)
  if !elem.elements["IDPSSODescriptor"].nil?
    return "idp_lists"
  end
  "sp_lists"
end

def create_entity_hash(elem, list_type)
  case list_type
  when "idp_lists"
    idp_elem = elem.elements["IDPSSODescriptor"]
    # the first certificate is used
    certificate = "-----BEGIN CERTIFICATE-----#{REXML::XPath.first(idp_elem, './/ds:X509Certificate', 'ds' => DS).text.gsub(/\s*$/, "")}\n-----END CERTIFICATE-----"
    saml2_http_redirect = nil
    idp_elem.elements.each("SingleSignOnService") do |e|
      if e.attributes["Binding"] == "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
        saml2_http_redirect = e.attributes["Location"]
      end
    end
    return {"certificate" => certificate,
            "saml2_http_redirect" => saml2_http_redirect}
  when "sp_lists"
    sp_elem = elem.elements["SPSSODescriptor"]
    # the first certificate is used
    certificate = REXML::XPath.first(sp_elem, './/ds:X509Certificate', 'ds' => DS).text
    saml2_http_post = nil
    sp_elem.elements.each("AssertionConsumerService") do |e|
      if e.attributes["Binding"] == "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
        saml2_http_post = e.attributes["Location"]
      end
    end
    return {"certificate" => certificate,
            "saml2_http_post" => saml2_http_post}
  end
end

def add_entities(entities, elem)
  list_type = get_list_type(elem)
  entity_id = elem.attributes["entityID"]
  entities[list_type][entity_id] = create_entity_hash(elem, list_type)
end

entities = {"idp_lists" => {}, "sp_lists" => {}}
doc.elements.each("EntityDescriptor") do |elem|
  add_entities(entities, elem)
end

doc.elements.each("EntitiesDescriptor/EntityDescriptor") do |elem|
  add_entities(entities, elem)
end

puts entities.to_yaml
