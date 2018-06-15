module Metadata
    module Formatter

        Key_order = %i[type id namespace_prefix full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]
        
        def format(format_type, full_name, read_result)
            case format_type
                when Metadata::FormatType::Tree
                    Metadata::TreeFormatter.format(full_name, read_result)
                when Metadata::FormatType::Mapping
                    Metadata::MappingFormatter.format(full_name, read_result)
                when Metadata::FormatType::Yaml
                    mapping_data = Metadata::MappingFormatter.format(full_name, read_result)
                    Metadata::YamlFormatter.format(full_name, mapping_data)
                when Metadata::FormatType::Edit
                    Metadata::UpdateFormatter.format(full_name, read_result)
                else
                    raise StandardError.new("Invalid format type")
            end
        end

        def format_metadata_list(metadata_list)
            added_metadata_list = add_missing_key(metadata_list)
            added_metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|hash| hash[:full_name]}
        end

        def add_missing_key(metadata_list)
            modified_list = Array[metadata_list].compact.flatten
            modified_list.each{ |hash| hash.store(:namespace_prefix, "") unless hash.has_key?(:namespace_prefix) }
        end

        def format_parent_tree_nodes(metadata_list)
            Metadata::TreeFormatter.get_parent_tree_nodes(metadata_list)
        end
    end
end