require "fileutils"

module Metadata
	module FieldTypeFormatter

		def format_field_type(metadata_type, type_fields)
			@result = []
			modified_field_types = Metadata::ValueFieldSupplier.add_missing_fields(metadata_type, type_fields)
			modified_field_types.each{|hash| parse_field_types(nil, hash)}
			validate_result
		    @result
		end

		def validate_result
		    file_name = 'C:\Users\murakosi\rubytestparse.log'
		    if File.exist?(file_name)
		    	FileUtils.rm(file_name)
		    end
		    file = File.open(file_name,'a')

		    @result.each do |h|
		        file.puts h
		    end
		    file.close
		    
		    chk = {}
		    @result.each do |h|
		        h.each do |k,v|
		            if chk.has_key?(k)
		                raise Exception.new("aaa")
		            else
		                chk[k] = v
		            end
		        end
		    end	
		end

		def parse_field_types(parent, hash)
            hash.each do |k, v|
                if k == :fields
                    parse_fields(parent, hash)
                else
                    if parent.nil?
                        @result << {hash[:name] => hash}
                    else
                        @result << {parent => hash }
                    end
                end
                break
            end
		end

		def parse_fields(parent, hash)
		    remnant = hash.delete(:fields)
		    if parent.nil?
		        key = hash[:name]#get_soap(h)
		    else
		        key = parent
		    end
		    parse_field_types(key, hash)

		    if remnant.present?
		        remnant = Array[remnant].flatten
		        remnant.each do |hash|
		            parse_field_types(key + "." + hash[:name], hash)
		        end
		    end
		end
	end
end