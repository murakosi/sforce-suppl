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
=begin
		def mapping_exists?(metadata_type)
			if !typefield_resource_exists?(metadata_type)
				return false
			end

			mapping_file = Service::ResourceLocator.call(@typefield_mapping)
			if mapping_file.present?
				@mapping = YAML.load_file(mapping_file)
			end

			@mapping.present?
		end
=end
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
=begin			
			if !mapping_exists?(metadata_type, Build_mapping)
				return type_fields
			end

			value_type_fields = []
			
			write_log(type_fields)
			
			type_fields.each do |hash|
				if @mapping.keys.include?(hash[:name])
					value_type_fields << @mapping[hash[:name]].symbolize_keys.merge(hash)
					@mapping.delete(hash[:name])
				else
					value_type_fields << hash
				end
			end
			@mapping.values.each{|hash| value_type_fields << hash.deep_symbolize_keys}
			
			value_type_fields
=end
=begin
			value_type_fields = []

			type_fields.each do |hash|
				if @mapping.keys.include?(hash[:name])
					value_type_fields << @mapping[hash[:name]].symbolize_keys
					@mapping.delete(hash[:name])
				#elsif Metadata::FieldType::SoapTypes.include?(hash[:soap_type])
				else
					value_type_fields << hash
				end
			end
			@mapping.values.each{|hash| value_type_fields << hash.deep_symbolize_keys}

			value_type_fields
=end

		end

		def rebuild(metadata_type, value_types, records)
			#@rebuild_result = {}
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
=begin
		def merge_nest(hash)
			hash.each do |k, v|
		        if @rebuild_result.has_key?(k)
		            @rebuild_result.deep_merge!({k=> v})
		        else
		            @rebuild_result.merge!(hash)
		        end
			end
		end
=end		
		def encode_content(key, value)
			if key.to_s.downcase == "content"
				Base64.strict_encode64(value)
			else
				value
			end
		end

=begin
		def rebuild(metadata_type, records)
			if !mapping_exists?(metadata_type, Rebuild_mapping)
				simple_reconstruct(records)
				#records
			else
				reconstruct(records)
			end
		end

		def simple_reconstruct(records)
			rebuild_result = {}
			records.each do |record|
			 	record.each do |k,v|
			 		rebuild_result.store(k, encode_content(k, v))
			 	end
			end
			rebuild_result
		end

		def reconstruct(records)
			rebuild_fields = @mapping["rebuild_fields"]
			skip_fields = @mapping["skip_fields"]

			rebuild_result = {}
			records.each do |record|
			 	record.each do |k, v|
			 		next if skip_fields.include?(k)

					if rebuild_fields.keys.include?(k)						
						fields = []
						rebuild_fields[k].each do | field_key, field_hash|
							field_hash.each do | source_key, rebuild_key |
								fields << rebuild_key
								fields << encode_content(rebuild_key, record[source_key])
							end
							rebuild_result.store(field_key, Hash[*fields])
						end						
					else
						rebuild_result.store(k, encode_content(k, v))
					end
				end
			end

			rebuild_result
		end

		def encode_content(key, value)
			if key.to_s.downcase == "content"
				Base64.strict_encode64(value)
			else
				value
			end
		end
=end
	end
	end
end