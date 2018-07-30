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
				metadata_list = list_metadata(sforce_session, "Profile").map{|h| h[:full_name]}
				metadata_list.each do |h|
					mapping_hash["adding"][h] = {"name" => "profile." + h, :soap_type => "string", :min_occurs => 0, :picklist_values => [{:value => "Read"},{:value => "Read/Write"}], :prior => true}
				end
				mapping_hash["adding"]["profile"] = {"name" => "profile", :soap_type => "string", :min_occurs => 0, :prior => true}
			end
			mapping_hash
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