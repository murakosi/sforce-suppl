require "cgi"

module Generator
	module GridDataGenerator

		def list_grid_column_options(metadata_list)
        	column_options = [{:type => "checkbox", :readOnly => false, :className => "htCenter htMiddle"}]
        	metadata_list.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        	{
        		:rows => metadata_list.map{|hash| [false] + hash.values.map{|value| unescape(value)}},
	            :column_options => column_options,
	            :columns => [""] + metadata_list.first.keys
            }

		end
		
		def unescape(value)
			if value.is_a?(Nori::StringWithAttributes) || value.is_a?(String)
				CGI.unescape(value)
			else
				value
			end
		end

		def api_crud_info(type_fields)
			type_fields.reject{|k, v| k == :value_type_fields}
		end

	end
end