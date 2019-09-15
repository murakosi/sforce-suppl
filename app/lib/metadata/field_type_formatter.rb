require "fileutils"

module Metadata
	module FieldTypeFormatter

		def format_field_type(sforce_session, metadata_type, type_fields)
			@result = []
			
			#custom_type_fields = Metadata::ValueFieldSupplier.add_missing_fields(sforce_session, metadata_type, type_fields)
			#@adding = custom_type_fields["adding"]
			#@removing = custom_type_fields["removing"]
			modified_field_types = type_fields
			modified_field_types.each{|hash| parse_field_types(nil, hash)}
			#add_remaining_fields()

			if !Rails.env.production?
				validate_result
			end

		    @result
		end

		def validate_result
			file_name = File.expand_path("log/" + "field_type_validate.log", Rails.root)

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
		    chk = {}
		end

		def parse_field_types(parent, hash)
            hash.each do |k, v|
                if hash.has_key?(:fields)
                    parse_fields(parent, hash)
                else
                    if parent.nil?
                        #type_field_hash = get_type_field_hash(hash[:name], hash)
                        type_field_hash = {hash[:name] => hash}
                    else
                        #type_field_hash = get_type_field_hash(parent, hash)
                        type_field_hash = {parent => hash}
                    end

                    @result << type_field_hash unless type_field_hash.nil?
                end
                break
            end
		end

		def get_type_field_hash(key, value)
			if @removing.include?(key)
				return nil
			end

			if !@adding.has_key?(key)
				return {key => value}
			end

			adding_value = @adding[key].symbolize_keys
			
			if adding_value.has_key?(:replace)
				new_value = adding_value
			else
				new_value = @adding[key].symbolize_keys.merge(value)
			end
			
			@adding.delete(key)
			
			return {key => new_value}
		end
=begin        
		def add_remaining_fields
				@adding.values.each{|hash| @result << { hash["name"] => hash.deep_symbolize_keys } }
		end
=end
		def parse_fields(parent, hash)
		    remnant = hash.delete(:fields)
			if parent.nil?
				key = hash[:name]
		    else
		        key = parent
		    end
		    parent_min_occurs = hash[:min_occurs]
		    parse_field_types(key, hash.merge({:parent => true}))

		    if remnant.present?
		        remnant = Array[remnant].flatten
		        remnant.each do |hash|
		            parse_field_types(key + "." + hash[:name], hash.merge({:min_occurs => parent_min_occurs}))
		        end
		    end
		end
	end
end