module Metadata
    module Formatter
        include Generator::TreeNodeGenerator
        include Metadata::FieldTypeFormatter
        include Utils::FormatUtils

        Key_order = %i[type id namespace_prefix full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

        def format_read_result(full_name, read_result, type_info)
            if read_result.nil?
                raise StandardError.new("No read results")
            else
                generate_nodes(full_name, read_result, type_info)
            end
        end

        def format_metadata_list(metadata_list)
            added_metadata_list = add_metadata_list_missing_key(metadata_list)
            added_metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|hash| hash[:full_name]}
        end

        def add_metadata_list_missing_key(metadata_list)
            modified_list = Array[metadata_list].compact.flatten
            modified_list.each{ |hash| hash.store(:namespace_prefix, "") unless hash.has_key?(:namespace_prefix) }
        end

        def format_parent_tree_nodes(api_crud_info, metadata_list)
            generate_parent_nodes(api_crud_info, metadata_list)
        end
        
        def format_field_type_result(sforce_session, metadata_type, field_type_result)
            format_field_type(sforce_session, metadata_type, field_type_result[:value_type_fields])
        end        
    end
end