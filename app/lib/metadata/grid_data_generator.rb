module Metadata
	module GridDataGenerator

		def list_grid_column_options(metadata_list)
        	column_options = [{:type => "checkbox", :readOnly => false, :className => "htCenter htMiddle"}]
        	metadata_list.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        	{
        		:rows => metadata_list.map{|hash| [false] + hash.values},
	            :column_options => column_options,
	            :columns => [""] + metadata_list.first.keys
            }

		end
		
		def create_grid_options(type_fields)
			@columns = []
			@column_options = []
			@field_names = []
			type_fields[:value_type_fields].each{|hash| generate(hash, create_grid_column, create_grid_column_option)}
			{
				:rows => [Array.new(@columns.size)],
				:columns => @columns,
				:field_names => @field_names,
				:column_options => @column_options,
				:context_menu => true,
				:min_row => min_row(type_fields)
			}
		end

		def generate(hash, column_func, option_func)
			@columns << column_func.call(hash)
			@column_options << option_func.call(hash)
		end

		def create_grid_column
			proc{|hash|
				@field_names << hash[:name]
			    if hash[:is_name_field] || hash[:min_occurs].to_i > 0
			        hash[:name] + "(*)"
			    else
			        hash[:name]
			    end
			}
		end

		def create_grid_column_option
			proc{|hash|
			    if hash[:soap_type] == "boolean"
			        type = {:type => "checkbox", :className => "htCenter htMiddle"}
			    elsif hash.has_key?(:picklist_values)
			        type = {:type => "autocomplete", :source => hash[:picklist_values].map{|hash| hash[:value]}}
			    else
			        type = {:type => "text"}
				end
			}
		end

		def min_row(type_fields)
			if type_fields[:api_creatable]
				1
			else
				0
			end
		end

		def api_crud_info(type_fields)
			type_fields.reject{|k, v| k == :value_type_fields}
		end

	end
end