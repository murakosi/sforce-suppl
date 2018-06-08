require "hashie"

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
			raw_result[:records]
		end

		def update(source, path, new_text)
			#Service::MetadataClientService.call(sforce_session).update(:CustomLabels, r)
			p update_source(source, path, new_text)
		end

		def update_source(source, path, new_text)
			mash = Hashie::Mash.new(source)
			update = "mash." + path + " = new_text"
			p update
			eval(update)
			mash.to_hash
		end
	end
end