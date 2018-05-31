module Metadata
	class MetadataResults
		class << self

			def metadata_type_changed?(metadata_type)
				@current_metadata_type != metadata_type
			end

			def store_list_result(metadata_type, result)
				if metadata_type_changed?(metadata_type)
					initialize_results(metadata_type)
				end
				@list_results[metadata_type] = result
			end

			def list_result(metadata_type)
				if metadata_type_changed?(metadata_type)
					initialize_results(metadata_type)
				end
				@list_results[metadata_type]
			end

			def full_name_changed?(metadata_type, full_name)
				if metadata_type_changed?(metadata_type)
					return false
				end
				@current_full_name != full_name
			end

			def store_read_result(metadata_type, full_name, result)
				if metadata_type_changed?(metadata_type)
					initialize_results(metadata_type)
				end		
				@read_results[full_name] = result
			end

			def read_result(metadata_type, full_name)
				if metadata_type_changed?(metadata_type)
					initialize_results(metadata_type)
				end
				@read_results[full_name]
			end

			def clear
				@current_metadata_type = nil
				@list_results = {}
				@read_results = {}
			end

			def initialize_results(metadata_type)
				@current_metadata_type = metadata_type
				@list_results = {}
				@read_results = {}
			end
		end
	end
end