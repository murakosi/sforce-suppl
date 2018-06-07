module Metadata
	module MetadataReader
		def get_metadata_types(sforce_session)
			Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
		end

		def list_metadata(sforce_session, metadata_type)
			Service::MetadataClientService.call(sforce_session).list(metadata_type)
		end

		def read_metadata(sforce_session, metadata_type, full_name)
			raw_result = Service::MetadataClientService.call(sforce_session).read(metadata_type, full_name)
			p raw_result[:records].to_xml
			raw_result[:records]
		end

		def update(result)
			#p result
			#r = result.delete("@xsi:type")
			r = result
			#p r
			Service::MetadataClientService.call(sforce_session).update(:CustomLabels, r)
		end
	end
end