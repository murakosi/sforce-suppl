module Metadata
    module Builder
        include Metadata::TreeNodeBuilder
        include Metadata::ValueTypeBuilder
        include Utils::FormatUtils

        Key_order = %i[type id namespace_prefix full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

        def build_read_result(full_name, read_result, type_info)
            if read_result.nil?
                raise StandardError.new("No read results")
            else
                build_tree_nodes(full_name, read_result, type_info)
            end
        end

        def build_metadata_list(metadata_list)
            add_missing_key(metadata_list).map{ |hash| hash.slice(*Key_order)}.sort_by{|hash| hash[:full_name]}
        end
        
        def build_field_type_result(metadata_type, field_type_result)
            build_value_type(metadata_type, field_type_result[:value_type_fields])
        end

        private

        def add_missing_key(metadata_list)
            Array[metadata_list].compact.flatten.each{ |hash| hash.store(:namespace_prefix, "") unless hash.has_key?(:namespace_prefix) }
        end        
    end
end