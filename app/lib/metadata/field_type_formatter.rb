require "fileutils"

module Metadata
	module FieldTypeFormatter

		def format_field_type(metadata_type, type_fields)
			@result = []
			#modified_field_types = Metadata::ValueFieldSupplier.add_missing_fields(metadata_type, type_fields)
			@adding = Metadata::ValueFieldSupplier.add_missing_fields(metadata_type, type_fields)
			modified_field_types = type_fields
			modified_field_types.each{|hash| parse_field_types(nil, hash)}
			add_remaining_fields()
			validate_result			
		    @result
		end

		def validate_result
		    file_name = 'C:\Users\murakosi\rubytest\rubytestparse.log'
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
		                raise Exception.new("duplicate!! => " + k.to_s)
		            else
		                chk[k] = v
		            end
		        end
		    end	
		end

		def parse_field_types(parent, hash)
            hash.each do |k, v|
                if hash.has_key?(:fields)
                    parse_fields(parent, hash)
                else
                    if parent.nil?
                        #@result << {hash[:name] => hash}
                        @result << get_type_field_hash(hash[:name], hash)
                    else
                        #@result << {parent => hash }
                        @result << get_type_field_hash(parent, hash)
                    end
                end
                break
            end
		end

		def get_type_field_hash(key, value)
			if @adding.nil? || !@adding.has_key?(key)
				{key => value}
			else
				new_value = @adding[key].symbolize_keys.merge(value)
				@adding.delete(key)
				{key => new_value}
			end
		end

		def add_remaining_fields
			if @adding.present?
				@adding.values.each{|hash| @result << { hash["name"] => hash.deep_symbolize_keys } }
			end
		end

		def parse_fields(parent, hash)
		    remnant = hash.delete(:fields)
			if parent.nil?
				key = hash[:name]#get_soap(h)
		    else
		        key = parent
		    end
		    parent_min_occurs = hash[:min_occurs]
		    parse_field_types(key, hash.merge({:parent => true}))

		    if remnant.present?
		        remnant = Array[remnant].flatten
		        remnant.each do |hash|
		            #parse_field_types(key + "." + hash[:name], hash)		            
		            parse_field_types(key + "." + hash[:name], hash.merge({:min_occurs => parent_min_occurs}))
		        end
		    end
		end
	end
end