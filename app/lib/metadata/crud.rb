
module Metadata
	module Crud

		All_or_none_error = "ALL_OR_NONE_OPERATION_ROLLED_BACK"

		def read_metadata(sforce_session, metadata_type, full_name)
			raw_result = Service::MetadataClientService.call(sforce_session).read(metadata_type, full_name)
			raw_result[:records]
		end

		def edit_metadata(source, path, new_text, data_type)
			text = to_type(new_text, data_type)
			source = source.with_indifferent_access
			elements = ["source"] + path.split(".").map{|value| get_edit_key(value)}
			update = elements.join + " = text"
			eval(update)
			source.deep_symbolize_keys
		end

		def get_edit_key(value)
			if is_integer?(value)
				"[#{value}]"
			else
				"[\"#{value}\"]"
			end
		end

		def is_integer?(value)
			Integer(value) rescue false
		end

		def to_type(text, data_type)
			begin
				case data_type.to_s.downcase
				when "trueclass", "falseclass"
					text.to_bool
				when "integer"
					text.to_i
				when "float"
					text.to_f
				else
					text
				end
			rescue StandardError => ex
				raise StandardError.new("Invalid value for data type")
			end
		end

		def update_metadata(sforce_session, metadata_type, read_results, full_names)
			metadata = read_results.select{|k, v| full_names.include?(k)}.values
			if metadata.empty?
				raise StandardError.new("No metadata to update")
			end

			save_result = Service::MetadataClientService.call(sforce_session).update(metadata_type, metadata)
			parse_save_result(Metadata::CrudType::Update, save_result)
		end

		def delete_metadata(sforce_session, metadata_type, full_names)
			save_result = Service::MetadataClientService.call(sforce_session).delete(metadata_type, full_names)
			parse_save_result(Metadata::CrudType::Delete, save_result)
		end

		def parse_save_result(crud_type, crud_result)
			result = Array[crud_result].flatten
			if result.any?{|hash| !hash[:success]}
				crud_error_result(crud_type, result)
			else
				crud_success_result(crud_type, result)
			end
		end

		def crud_error_result(crud_type, result)
			result = result.select{|hash| !hash[:success]}

			if result.any?{|hash| hash.has_key?(:errors)}
				result = result.reject{|hash| hash[:errors][:status_code] == All_or_none_error}.first				
				error = result[:errors]
				raise StandardError.new(error[:status_code] + ": " + error[:message])
			else
				raise StandardError.new(crud_type.to_s.camelize + " metadata failed")
			end
		end

		def crud_success_result(crud_type, result)
			{
				:message => crud_type.to_s.camelize + " metadata succeeded",
				:refresh_required => refresh_required?(crud_type)
			}
		end

		def refresh_required?(crud_type)
	        case crud_type
	        when Metadata::CrudType::Read
	            return false
	        when Metadata::CrudType::Update
	            return false
	        when Metadata::CrudType::Delete
	            return true
			end
		end

	end
end