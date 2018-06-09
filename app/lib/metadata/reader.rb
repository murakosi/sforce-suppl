require "hashie"

module Metadata
	module Reader

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

		def update(source, path, new_text, data_type)
			#Service::MetadataClientService.call(sforce_session).update(:CustomLabels, r)
			p update_source(source, path, new_text, data_type)
		end

		def update_source(source, path, new_text, data_type)
			mash = Hashie::Mash.new(source)
			text = to_type(new_text, data_type)
			update = "mash." + path + " = text"
			eval(update)
			mash.to_hash
		end

		def to_type(text, data_type)
			begin
				case data_type.to_s
				when TrueClass.to_s, FalseClass.to_s
					text.to_bool
				when Integer.to_s
					text.to_i
				when Float.to_s
					text.to_f
				else
					text
				end
			rescue StandardError => ex
				raise StandardError.new("Invalid value for data type")
			end
		end
	end
end