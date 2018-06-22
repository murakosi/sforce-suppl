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
		
		def create_grid_options(metadata_type, result)
			min_row = create_grid_min_row(result)

			if min_row > 0
				get_create_grid_options(metadata_type, result)
			else
				nil_create_grid_options
			end
		end

		def get_create_grid_options(metadata_type, result)
			columns = []
			column_options = []
			field_names = []

			type_fields = Metadata::ValueFieldSupplier.add_missing_fields(metadata_type, result[:value_type_fields])
			type_fields = type_fields.sort_by{|hash| [create_grid_sort_key(hash), hash[:name]]}

			type_fields.each do |hash|
				field_names << hash[:name]
				columns << create_grid_column(hash)
				column_options << create_grid_column_option(hash)
			end

			{
				:rows => [Array.new(columns.size)],
				:columns => columns,
				:field_names => field_names,
				:column_options => column_options,
				:context_menu => true,
				:min_row => 1,
			}
		end

		def nil_create_grid_options
			{
				:rows => nil,
				:columns => nil,
				:field_names => nil,
				:column_options => nil,
				:context_menu => false,
				:min_row => 0,
			}
		end

		def create_grid_sort_key(hash)
			key = hash[:min_occurs].to_i
			if hash[:is_name_field]
				key += 1
			end
			-key
		end

		def create_grid_column(hash)
		    if hash[:is_name_field] || hash[:min_occurs].to_i > 0
		        "(*)" + hash[:name]
		    else
		        hash[:name]
		    end
		end

		def create_grid_column_option(hash)
		    if hash[:soap_type] == "boolean"
		        type = {:type => "checkbox", :className => "htCenter htMiddle"}
		    elsif hash.has_key?(:picklist_values)
		        type = {:type => "autocomplete", :source => hash[:picklist_values].map{|hash| hash[:value]}}
		    else
		        type = {:type => "text"}
			end
		end

		def create_grid_min_row(type_fields)
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