module Metadata
	module ValueTypeBuilder

	    def build_crud_info(type_fields)
	        type_fields.reject{|k, v| k == :value_type_fields}
	    end

		def build_value_type(metadata_type, type_fields)
			@formatted_field_type = []
			type_fields.each{|hash| parse_field_types(nil, hash)}
		    @formatted_field_type
		end


		private

		def parse_field_types(parent, hash)
            hash.each do |k, v|
                if hash.has_key?(:fields)
                    parse_fields(parent, hash)
                else
                    if parent.nil?
                        type_field_hash = {hash[:name] => hash}
                    else
                        type_field_hash = {parent => hash}
                    end

                    @formatted_field_type << type_field_hash unless type_field_hash.nil?
                end
                break
            end
		end

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