require "hashie"

module Metadata
	module Crud

		All_or_none_error = "ALL_OR_NONE_OPERATION_ROLLED_BACK"

		def get_metadata_types(sforce_session)
			metadata_types = Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
		end

		def list_metadata(sforce_session, metadata_type)
			Service::MetadataClientService.call(sforce_session).list(metadata_type)
		end

		def get_field_value_types(sforce_session, metadata_type)
			Service::MetadataClientService.call(sforce_session).describe_value_type(metadata_type)
		end

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
=begin
			mash = Hashie::Mash.new(source)
			text = to_type(new_text, data_type)
			update = "mash." + path + " = text"
			eval(update)
			mash.to_hash.deep_symbolize_keys
=end
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

		def update_metadata(sforce_session, metadata_type, metadata)
			save_result = Service::MetadataClientService.call(sforce_session).update(metadata_type, metadata)
			parse_save_result(Metadata::CrudType::Update, save_result)
		end

		def delete_metadata(sforce_session, metadata_type, full_names)
			save_result = Service::MetadataClientService.call(sforce_session).delete(metadata_type, full_names)
			parse_save_result(Metadata::CrudType::Delete, save_result)
		end

		def create_metadata(sforce_session, metadata_type, headers, types, values)
			metadata = prepare_metadata_to_create(metadata_type, headers, types, values)
			if metadata.has_key?(:subsequent)
				create_with_permissions(sforce_session, metadata_type, metadata)
			else
				create_without_permissions(sforce_session, metadata_type, metadata)
			end
			
=begin			
			p metadata
			metadata = {"profile" =>
				{:full_name => "Admin Profile",
				 :object_permissions => 
				 [
				 	{
				 		:object => "RB__c",
				 	 	:allow_create => true,
				 	 	:allow_delete => true,
				 	 	:allow_edit => true,
				 	 	:allow_read => true
				 	}
				 ]
				}
			}
			Service::MetadataClientService.call(sforce_session).update("Profile", metadata)		
			fake_response
=end
			#save_result = Service::MetadataClientService.call(sforce_session).create(metadata_type, metadata)
			#parse_save_result(Metadata::CrudType::Create, save_result)
		end

		def prepare_metadata_to_create(metadata_type, headers, types, values)
			source = []
			values.each do | value |
				merged = [headers, value].transpose
				source << Hash[*merged.flatten]
			end
			
			value_types = Hash[*[headers, types].transpose.flatten]
			Metadata::ValueFieldSupplier.rebuild(metadata_type, value_types, source)
		end

		def create_without_permissions(sforce_session, metadata_type, metadata)
			save_result = Service::MetadataClientService.call(sforce_session).create(metadata_type, metadata[:metadata])
			parse_save_result(Metadata::CrudType::Create, save_result)
		end

		def create_with_permissions(sforce_session, metadata_type, metadata)
			create_result = create_without_permissions(sforce_session, metadata_type, metadata)
			update_result = Service::MetadataClientService.call(sforce_session).update("Profile", metadata[:subsequent])
			parse_save_result(Metadata::CrudType::Update, update_result)
			create_result			
		end

		def fake_response
			{
				:message => "metadata succeeded",
				:refresh_required => false
			}
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
	        when Metadata::CrudType::Create
	            return false
	        when Metadata::CrudType::Update
	            return false
	        when Metadata::CrudType::Delete
	            return true
			end
		end

	end
end