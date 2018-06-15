require "savon"
require 'logger'
require "fileutils"
require 'zip'
require './Murakosi'

if File.exist?("log.txt")
	FileUtils.remove("log.txt")
end
log = Logger.new('log.txt')

c = Savon.client(:wsdl => "part.xml")
r = c.call(:login, :message => {:username => "murakoshi@cse.co.jp", :password=>"s13926cse"})
r = r.to_hash

r = r[:login_response]
r = r[:result]

metadata_server_url = "https://mrdk-dev-ed.my.salesforce.com/services/Soap/m/42.0/00D7F0000004Ad6"
server_url = "https://mrdk-dev-ed.my.salesforce.com/services/Soap/u/42.0/00D7F0000004Ad6"
session_id = r[:session_id]#"00D7F0000004Ad6!AQMAQHZPckQ5idk5oqxB_TwO7w61ZlA8oTg15crJB_ow0AnZGN_iKZgISzYbTj9g.O0N3JtOcszmqc9TCAkM4xeKUE.axNBX</sessionId><userId>0057F000000QYTFQA4"

headers = {"tns:SessionHeader" => {"tns:sessionId" => session_id}}

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

req4 = {:retrieve_request => {:api_version=> "42.0", :single_package => true, :unpackaged => Murakosi.package}}
message_hash = req4
response = meta.call(:retrieve) do |locals|
    locals.message message_hash
end

id = response.to_hash[:retrieve_response][:result][:id]
#{:retrieve_response=>{:result=>{:done=>false, :id=>"09S7F000003wsihUAA", :state=>"Queued"}}}
#{:check_retrieve_status_response=>{:result=>{:done=>false, :id=>"09S7F000003wsjLUAQ", :status=>"Pending", :success=>false, :zip_file=>nil}}}
res = nil
        loop do
          @status = nil
          sleep (1)

          if Murakosi.doCall(meta, {:id => id, :include_zip => false})[:status] == "Succeeded" || Murakosi.doCall(meta, {:id => id, :include_zip => false})[:status] == "Failed"
            res = Murakosi.doCall(meta, {:id => id, :include_zip => true})
            break
          end
        end
      
      if !res[:zip_file].nil?
       Murakosi.with_tmp_zip_file(res[:zip_file]) do |file|
          Zip::File.open(file) do |zip|
            zip.each do |f|
              path = File.join("C:\\Users\\murakosi\\rubytest\\", f.name)
              FileUtils.mkdir_p(File.dirname(path))
              zip.extract(f, path) { true }
            end
          end
          end
      else
        p res
    end
=begin
#delete custom field
req2 = "RB__c.to_delete__c"
a = {:metadata_type => "CustomField", :full_names => [req2] }

#create custom field
req = {:full_name=>"RB__c.to_delete__c", :label => "test field", :length=> 255, :type => "Text"}
a = {:metadata => [req], :attributes! => { :metadata => { 'xsi:type' => "tns:CustomField" }} }

=end