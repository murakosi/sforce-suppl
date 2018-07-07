module Metadata
	class ValueFieldSupplier
	class << self


		def write_log(text)
			File.write('C:\Users\murakosi\rubytest\ws_hash.log', text)
		end

		def typefield_resource_exists?(type)
			resouce_file_path = Service::ResourceLocator.call(:valuetypes)
			@typefield_mapping = YAML.load_file(resouce_file_path)[type]
			@typefield_mapping.present?
		end

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

		def add_missing_fields(metadata_type, type_fields)
			if mapping_exists?(metadata_type)
				return @mapping
			else
				nil
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

		def rebuild(metadata_type, records)
			@rebuild_result = {}
			temp_hash = {}
			records.each do |hash|
				hash.each do |k, v|
					next if v.nil?
					temp_hash = k.split(".").reverse.inject(encode_content(k,v)) {|mem, item| { item => mem } }
					merge_nest(temp_hash)
				end
			end			
			@rebuild_result
		end

		def merge_nest(hash)
			hash.each do |k, v|
		        if @rebuild_result.has_key?(k)
		            @rebuild_result.deep_merge!({k=> v})
		        else
		            @rebuild_result.merge!(hash)
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