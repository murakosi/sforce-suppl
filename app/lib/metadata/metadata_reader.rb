module Metadata
	module MetadataReader

        def results
            if @metadata_results.present?
                @metadata_results
            else
                @metadata_results = MetadataResults.new
            end
        end

		def get_metadata_types(sforce_session)
			Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
		end

		def list_metadata(sforce_session, metadata_type)
			if results.list_result(metadata_type).present?
				results.list_result(metadata_type)
			else
				metadata_list = Service::MetadataClientService.call(sforce_session).list(metadata_type)
				results.store_list_result(metadata_type, metadata_list)
			end
		end

		def read_metadata(sforce_session, metadata_type, full_name)
			if results.read_result(full_name).present?
				results.read_result(full_name)
			else
				read_result = Service::MetadataClientService.call(sforce_session).read(metadata_type, full_name)[:records]
				results.store_read_result(full_name, read_result)
			end
		end

		def format_result(format_type, full_name, result)

		end

		class MetadataResults

			def initialize
				@list_results = {}
				@read_results = {}
			end

			def store_list_result(metadata_type, result)
				@list_results[metadata_type] = result
			end

			def list_result(metadata_type)
				@list_results[metadata_type]
			end

			def store_read_result(full_name, result)
				@read_results[full_name] = result
			end

			def read_result(full_name)
				@read_results[full_name]
			end
		end

	end
end