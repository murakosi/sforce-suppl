module Metadata
	class ValueFieldSupplier
	class << self
		include Metadata::Crud
		include Metadata::SessionController

		Permission_required_types = ["CustomObject", "CustomField"]
		Permisson_option_splitter = ", "
		Permission_for_all = "All"

		def typefield_resource_exists?(type)
			resouce_file_path = Service::ResourceLocator.call(:valuetypes)
			@typefield_mapping = YAML.load_file(resouce_file_path)[type]
			@typefield_mapping.present?
		end

		def get_mapping_hash(sforce_session, metadata_type)
			mapping_file = Service::ResourceLocator.call(@typefield_mapping)
			mapping_hash = YAML.load_file(mapping_file)
			
			if Permission_required_types.include?(metadata_type)
				metadata_list = list_metadata(sforce_session, "Profile").map{|hash| hash[:full_name]}
				profile_list = metadata_list
				mapping_hash["adding"][Permission_for_all] = type_specific_hash(metadata_type, Permission_for_all)
				metadata_list.each do |name|
					mapping_hash["adding"][name] = type_specific_hash(metadata_type, name)
				end
				mapping_hash["adding"]["profile"] = {"name" => "profile", :soap_type => "string", :min_occurs => 0, :prior => true, :parent => true}
			end
			mapping_hash
		end

		def type_specific_hash(metadata_type, key)
			if metadata_type == "CustomObject"
				custom_object_hash(key)
			elsif metadata_type == "CustomField"
				custom_field_hash(key)
			end
		end

		def custom_object_hash(key)
			{
				"name" => "profile." + key,
				:soap_type => "multiselect",
				:min_occurs => 0,
				:priority => 1,
				:options => {
					:multiple => true,
					:splitter => Permisson_option_splitter,
					:data => [
								{:id => "allowCreate", :label => "allowCreate"},
								{:id => "allowDelete", :label => "allowDelete"},
								{:id => "allowEdit", :label => "allowEdit"},
								{:id => "allowRead", :label => "allowRead"},
								{:id => "modifyAllRecords", :label => "modifyAllRecords"},
								{:id => "viewAllRecords", :label => "viewAllRecords"}
							 ]
							}
			}
		end

		def custom_field_hash(key)
			{
				"name" => "profile." + key,
				:soap_type => "multiselect",
				:min_occurs => 0,
				:priority => 1,
				:options => {
					:multiple => true,
					:splitter => Permisson_option_splitter,
					:data => [
								{:id => "readable", :label => "readable"},
								{:id => "editable", :label => "editable"}
							 ]
							}
			}
		end

		def add_missing_fields(sforce_session, metadata_type, type_fields)
			if typefield_resource_exists?(metadata_type)
				#mapping_file = Service::ResourceLocator.call(@typefield_mapping)
				#return YAML.load_file(mapping_file)
				get_mapping_hash(sforce_session, metadata_type)
			else
				#nil
				{"adding" => {}, "removing" => []}
			end
		end

		def rebuild(metadata_type, value_types, records)			
			@rebuild_permission_required = false

			@main_hash_array = rebuild_main(metadata_type, value_types, records)

			if @rebuild_permission_required				
				permission_hash_array = rebuild_permission(metadata_type)
				rebuild_result = {:metadata => @main_hash_array, :subsequent => permission_hash_array}
			else
				rebuild_result = {:metadata => @main_hash_array}
			end
			
			rebuild_result
		end

		def rebuild_main(metadata_type, value_types, records)
			main_hash_array = []

			records.each do |hash|

				@merged_hash = {}

				hash.each do |k, v|
					next if v.nil? || v == ""

					if k.include?("profile.") && Permission_required_types.include?(metadata_type)
						@rebuild_permission_required = true
					end

					if value_types[k] == "array"
					    value = v.split(",").map(&:strip)
					elsif value_types[k] == "name_array"
					    value_array = v.split(",").map(&:strip)
					    value = value_array.map{|name| {:full_name => name}}					
					else
					    value = v
					end

					temp_hash = k.split(".").reverse.inject(encode_content(k,value)) {|mem, item| { item => mem } }					
					merge_hash(temp_hash)
				end

				main_hash_array << @merged_hash
			end

			main_hash_array
		end

		def merge_hash(hash)
			hash.each do |k, v|
		        if @merged_hash.has_key?(k)
		            @merged_hash.deep_merge!({k=> v})
		        else
		            @merged_hash.merge!(hash)
		        end
			end
		end		

		def rebuild_permission(metadata_type)
			permission_hash_array = []

			@main_hash_array.each_with_index do |hash, index|

				target_full_name = hash["fullName"]
				profile_record = hash.delete("profile")
				@main_hash_array[index] = hash

				profile_record.each do |k, v|
				    
				    if k == Permission_for_all
				        permission_hash_array << get_all_permission(metadata_type, target_full_name, v)
				        permission_hash_array = permission_hash_array.flatten
				    else
				        permission_hash_array << get_each_permissino(metadata_type, target_full_name, k, v)
				    end
=begin
					value_hash = {}

				    v.split(Permisson_option_splitter).map(&:strip).map{|name| value_hash.merge!({name.to_sym => true})}
				    permission = {
				    				:full_name => k,
				    				permission_key(metadata_type) => 
				    				[
				    					{
				    						permission_object(metadata_type) => target_full_name
					    				}.merge!(value_hash)
				    				]	    				
				    			}
					
					#permission_hash_array << {:profile => permission}
					permission_hash_array << permission
				end
=ed				
			end

			group_by_profile(metadata_type, permission_hash_array)
		end
		
		def get_each_permissino(metadata_type, target_full_name, key, value)
			value_hash = {}

		    value.split(Permisson_option_splitter).map(&:strip).map{|name| value_hash.merge!({name.to_sym => true})}
		    permission = {
		    				:full_name => key,
		    				permission_key(metadata_type) => 
		    				[
		    					{
		    						permission_object(metadata_type) => target_full_name
			    				}.merge!(value_hash)
		    				]	    				
		    			}
	    end
	    
		def get_all_permission(metadata_type, target_full_name, value)
		    permission_array = []
		    
		    profiles = profile_list
		    if profiles.nil?
		        raise StandardError.new("Failed to get profiles. List metadata again.")
		    end
		    
		    value_hash = {}
		    value.each do |k, v|
		        v.split(Permisson_option_splitter).map(&:strip).map{|name| value_hash.merge!({name.to_sym => true})}
		    end
		    
		    profiles.each do |profile|
				    permission = {
				    				:full_name => profile,
				    				permission_key(metadata_type) => 
				    				[
				    					{
				    						permission_object(metadata_type) => target_full_name
					    				}.merge!(value_hash)
				    				]	    				
				    			}
				    permission_array << permission
			end
			permission_array
		end

		def group_by_profile(metadata_type, source)
			#result = []
			
			groups = source.group_by{|hash| hash[:full_name]}
			
			groups.each_with_object([]) do |(k, v), result|
			    full_name = {:full_name => k}
			    permissions = v.map{|hash| hash[permission_key(metadata_type)]}.flatten
				result << full_name.merge({permission_key(metadata_type) => permissions})
			end
			
			#result
		end
		
		def permission_key(metadata_type)
			if metadata_type == "CustomObject"
				:object_permissons
			elsif metadata_type == "CustomField"
				:field_permissions
			end
		end

		def permission_object(metadata_type)
			if metadata_type == "CustomObject"
				:object
			elsif metadata_type == "CustomField"
				:field
			end
		end

		def encode_content(key, value)
			if key.to_s.downcase == "content"
				Base64.strict_encode64(value)
			else
				value
			end
		end

	end
	end
end