module Metadata
    module MetadataFormatter

        Key_order = %i[type id namespace_prefix full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]
        
        def format(format_type, full_name, read_result)
            case format_type
                when Metadata::MetadataFormatType::Tree
                    Metadata::TreeFormatter.format(full_name, read_result)
                when Metadata::MetadataFormatType::Mapping
                    Metadata::MappingFormatter.format(full_name, read_result)
                when Metadata::MetadataFormatType::Yaml
                    mapping_data = Metadata::MappingFormatter.format(full_name, read_result)
                    Metadata::YamlFormatter.format(full_name, mapping_data)
                else     
                    raise StandardError.new("Invalid format type")
            end
        end

        def format_metadata_list(metadata_list)
            if metadata_list.is_a?(Hash)
                [metadata_list.slice(*Key_order)]
            else
                metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|k,v| k[:full_name]}
            end
        end

        def format_parent_tree_nodes(metadata_list)
            Metadata::TreeFormatter.get_parent_tree_nodes(metadata_list)
        end
    end
end