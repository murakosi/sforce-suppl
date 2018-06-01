module Metadata
	class MetadataReader
		class << self

			def get_metadata_types(sforce_session)
				Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
			end

			def list_metadata(sforce_session, metadata_type)
				Service::MetadataClientService.call(sforce_session).list(metadata_type)
			end

			def read_metadata(sforce_session, metadata_type, full_name)
				Service::MetadataClientService.call(sforce_session).read(metadata_type, full_name)[:records]
			end
		end
	end
end