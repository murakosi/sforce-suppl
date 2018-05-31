module Metadata
	class MetadataReader
		class << self

			def clear
				Metadata::MetadataResults.clear
			end

			def get_metadata_types(sforce_session)
				Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
			end

			def list_metadata(sforce_session, metadata_type)
				if Metadata::MetadataResults.list_result(metadata_type).present?
					return Metadata::MetadataResults.list_result(metadata_type)
				end

				metadata_list = Service::MetadataClientService.call(sforce_session).list(metadata_type)
				Metadata::MetadataResults.store_list_result(metadata_type, metadata_list)
			end

			def read_metadata(sforce_session, metadata_type, full_name)
				if Metadata::MetadataResults.read_result(metadata_type, full_name).present?
					return Metadata::MetadataResults.read_result(metadata_type, full_name)
				end

				read_result = Service::MetadataClientService.call(sforce_session).read(metadata_type, full_name)[:records]
				Metadata::MetadataResults.store_read_result(metadata_type, full_name, read_result)
			end
		end
	end
end