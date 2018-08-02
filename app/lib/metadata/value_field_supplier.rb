module Metadata
	class ValueFieldSupplier
	class << self
		include Metadata::Crud

		Permission_required_types = ["CustomObject", "CustomField"]

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
				:prior => true,
				:options => {
					:multiple => true,
					:data => [
								{:id => 1, :label => "allowCreate"},
								{:id => 2, :label => "allowDelete"},
								{:id => 3, :label => "allowEdit"},
								{:id => 4, :label => "allowRead"},
								{:id => 5, :label => "modifyAllRecords"},
								{:id => 6, :label => "viewAllRecords"}
							 ]
							}
			}
		end

		def custom_field_hash(key)
			{
				"name" => "profile." + key,
				:soap_type => "multiselect",
				:min_occurs => 0,
				:prior => true,
				:options => {
					:multiple => true,
					:data => [
								{:id => 1, :label => "readable"},
								{:id => 2, :label => "editable"}
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
			@rebuild_result = []

			records.each do |hash|

				@merged_hash = {}

				hash.each do |k, v|
					next if v.nil?
					
					if value_types[k] == "array"
					    value = v.split(",").map(&:strip)
					elsif value_types[k] == "name_array"
					    value_array = v.split(",").map(&:strip)
					    value = value_array.map{|name| {:full_name => name}}
					else
					    value = v
					end
					temp_hash = k.split(".").reverse.inject(encode_content(k,value)) {|mem, item| { item => mem } }
					#p temp_hash
					merge_hash(temp_hash)
				end

				@rebuild_result << @merged_hash
			end

			@rebuild_result
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