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
  if elem.elements.any? {|el| el.has_name?("IDPSSODescriptor")}
    return "idp_lists"
  end
  "sp_lists"
end

def create_entity_hash(elem, list_type)
  case list_type
  when "idp_lists"
    idp_elem = elem.elements.find {|el| el.has_name?("IDPSSODescriptor")}
    # the first certificate is used
    cert_elem = REXML::XPath.first(idp_elem, './/ds:X509Certificate', 'ds' => DS)
    # reject an IdP without a certificate
    if cert_elem.nil?
      puts "specified metadata has an IdP without certificate!"
      exit 1
    end
    # Cert must be split to 64 char lines (else OpenSSL gives "nested asn1" error)
    certificate = "-----BEGIN CERTIFICATE-----\n#{cert_elem.text.gsub(/\s+/, "").scan(/.{1,64}/).join("\n")}\n-----END CERTIFICATE-----"
    saml2_http_redirect = nil
    idp_elem.elements.find_all {|el| el.has_name?("SingleSignOnService")}.each do |e|
      if e.attributes["Binding"] == "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
        saml2_http_redirect = e.attributes["Location"]
      end
    end
    return {"certificate" => certificate,
            "saml2_http_redirect" => saml2_http_redirect}
  when "sp_lists"
    sp_elem = elem.elements.find {|el| el.has_name?("SPSSODescriptor")}
    #puts sp_elem.attributes["entityID"]
    # the first certificate is used
    # permit a SP without a certificate
    cert_elem = REXML::XPath.first(sp_elem, './/ds:X509Certificate', 'ds' => DS)
    certificate = cert_elem.nil? ? "" : "-----BEGIN CERTIFICATE-----\n#{cert_elem.text.gsub(/\s+/, "").scan(/.{1,64}/).join("\n")}\n-----END CERTIFICATE-----"
    saml2_http_post = nil
    sp_elem.elements.find_all {|el| el.has_name?("AssertionConsumerService")}.each do |e|
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
doc.elements.find_all {|el| el.has_name?("EntityDescriptor")}.each do |elem|
  add_entities(entities, elem)
end

doc.elements.find_all {|el| el.has_name?("EntitiesDescriptor")}.each do |elem1|
  elem1.elements.find_all {|el| el.has_name?("EntityDescriptor")}.each do |elem2|
    add_entities(entities, elem2)
  end
end

puts entities.to_yaml
