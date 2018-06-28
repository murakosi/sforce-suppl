require "savon"
require 'logger'
require "fileutils"
require 'zip'
require './Murakosi'
require "wasabi"
require 'active_support'
require 'active_support/core_ext'

=begin
if File.exist?("log.txt")
	FileUtils.remove("log.txt")
end
log = Logger.new('log.txt')

c = Savon.client(:wsdl => "tooling.xml")
r = c.call(:login, :message => {:username => "murakoshi@cse.co.jp", :password=>"s13926cse"})
r = r.to_hash
r = r[:login_response]
r = r[:result]

metadata_server_url = r[:metadata_server_url]
server_url = r[:server_url]
session_id = r[:session_id]
headers = {"tns:SessionHeader" => {"tns:sessionId" => session_id}}

tool = Savon.client(:wsdl => "tooling.xml",
soap_header: headers,
endpoint: server_url,
ssl_version: :TLSv1_2,
log: true, 
logger: log, 
log_level: :debug,
pretty_print_xml: true,
convert_request_keys_to: :lower_camelcase
)

meta = Savon.client(:wsdl => "metadata.xml",
soap_header: headers,
endpoint: metadata_server_url,
ssl_version: :TLSv1_2,
log: true, 
logger: log, 
log_level: :debug,
pretty_print_xml: true,
convert_request_keys_to: :lower_camelcase
)
=end

hash = Hash.from_xml(open('tooling.xml'))
a = hash["definitions"]["types"]["schema"]

b = a.map{|hash| hash["simpleType"]}.compact.flatten

if File.exist?("ws_hash.log")
	FileUtils.remove("ws_hash.log")
end
#file = File.open('ws_hash.log','a')
#    b.each do |h|
#        file.puts h
#    end
#file.close

c = []
i = 0
b.each do |hash|
    next unless hash.has_key?("restriction") && hash["restriction"].has_key?("enumeration")
    name = hash["name"]
    enums = hash["restriction"]["enumeration"].to_a.flatten.map{|hash| hash["value"]}
    c << {name => enums}
end
file = File.open('ws_hash.log','a')
    c.each do |h|
        file.puts h
    end
file.close
=begin
metadata_type = "DeleteConstraint"
req4 =  {:type => "{urn:metadata.tooling.soap.sforce.com}" + metadata_type.to_s}
message_hash = req4
response = meta.call(:describe_value_type) do |locals|
    locals.message message_hash
end

=end