require "savon"
require 'tempfile'

class Murakosi
class << self
def doCall(client, param)
    response = client.call(:check_retrieve_status) do |locals|
        locals.message param
    end
    response = response.to_hash[:check_retrieve_status_response][:result]
end

def package()
    member = "Account"
    b = {:types => {:members => [member], :name => "CustomObject"}}
    #h = {:custom_object => ["Account"]}
    #x = to_xml(h)
    #to
end

    def with_tmp_zip_file(z_file)
      file = Tempfile.new('retrieve')
      begin
        file.binmode
        file.write(zip_file(z_file))
        file.rewind
        yield file
      ensure
        file.close
        file.unlink
      end
    end
    
    def zip_file(file)
      Base64.decode64(file)
    end
    
end
end