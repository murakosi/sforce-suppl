require "yaml"

module Generator
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
		
		def create_grid_options(metadata_type, crud_info, type_fields)
			#min_row = create_grid_min_row(result)

			#if min_row > 0
			if crud_info[:api_creatable]
				get_create_grid_options(metadata_type, type_fields)
			else
				nil_create_grid_options
			end
		end

		def get_create_grid_options(metadata_type, type_fields)
			columns = []
			column_options = []
			field_names = []
			field_types = []
			@enums = Metadata::EnumProvider.enums
			#type_fields = Metadata::ValueFieldSupplier.add_missing_fields(metadata_type, result[:value_type_fields])

			#type_fields.each do |hash|
			#	field_names << hash[:name]
			#	columns << create_grid_column(hash)
			#	column_options << create_grid_column_option(hash)
			#end
			
			sorted_type_fields = type_fields.sort_by{|hash| [create_grid_sort_key(hash), hash.keys]}
			
			sorted_type_fields.each do |hash|
				hash.each do |k, v|
					field_names << k
					field_types << v[:soap_type]
					columns << create_grid_column(k, v)
					column_options << create_grid_column_option(v)
				end
			end

			{
				:rows => [Array.new(columns.size)],
				:columns => columns,
				:field_names => field_names,
				:field_types => field_types,
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

=begin	
		def create_grid_sort_key(hash)
			key = hash[:min_occurs].to_i
			if hash[:is_name_field]
				key += 1
			end
			-key
		end
=end
		def create_grid_sort_key(hash)
			key = hash.keys.first
			value = Hash[*hash.values]
			sort_key = 0 #value[:min_occurs].to_i

			if is_key_field?(key, value)
				#if hash.keys.first.include?(".")
				#	if value.has_key?(:indispensable)
				#		key += 1
				#	else
				#		key -= 1
				#	end
				#else
					sort_key += 1
				#end
			end

			if is_name_field?(key, value)
				sort_key += 1
			end

			if value.has_key?(:prior)
				sort_key += 1
			end
=begin
			if value[:is_name_field]
				key += 1
			end
			
			if value[:name].to_s.camelize(:lower) == "fullName"
				key += 1
			end

			if value.has_key?(:indispensable)
				key += 1
			end
=end
			-sort_key
		end

		def is_key_field?(key, value)
			if is_name_field?(key, value)
				return true
			elsif value[:min_occurs].to_i > 0
				return true
			elsif value.has_key?(:indispensable)
				return true			
			end	

			return false		
		end

		def is_name_field?(key, value)
			if value[:name].to_s.camelize(:lower) == "fullName" && !key.include?(".")
				return true
			else
				return false
			end
		end

		def create_grid_column(key, hash)
		    #if hash[:is_name_field] || hash[:min_occurs].to_i > 0 || hash.has_key?(:indispensable)
		    if is_key_field?(key, hash)
		        "*" + key
		    else		    	
		         key
		    end
		end
=begin
		def create_grid_column(hash)
		    if hash[:is_name_field] || hash[:min_occurs].to_i > 0
		        "*" + hash[:name]
		    else
		         hash[:name]
		    end
		end
=end

=begin
		def create_grid_column_option(hash)
		    if hash[:soap_type] == "boolean"
		        type = {:type => "checkbox", :className => "htCenter htMiddle"}
		    elsif hash.has_key?(:picklist_values)
				type = {:type => "autocomplete", :source => hash[:picklist_values].map{|hash| hash[:value]}}
		    else
		        type = {:type => "text"}
			end
		end
=end
		def create_grid_column_option(hash)
			if hash[:parent]
				type = {:readOnly => true}
		    elsif hash[:soap_type] == "boolean"
		        type = {:type => "checkbox", :className => "htCenter htMiddle", :checkedTemplate => true, :uncheckedTemplate => nil}
		    elsif hash.has_key?(:picklist_values)
				type = {:type => "autocomplete", :source => hash[:picklist_values].map{|hash| hash[:value]}}
			elsif @enums.has_key?(hash[:name])
				type = {:type => "autocomplete", :source => @enums[hash[:name]]}
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