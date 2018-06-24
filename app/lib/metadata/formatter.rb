module Metadata
    module Formatter
        include Utils::FormatUtils

        Key_order = %i[type id namespace_prefix full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

        def format_read_result(full_name, read_result)
            if read_result.nil?
                raise StandardError.new("No read results")
            else
                @full_name = full_name
                parse_hash(read_result, full_name)
            end
        end        
=begin        
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
=end
        def format_metadata_list(metadata_list)           
            added_metadata_list = add_missing_key(metadata_list)
            added_metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|hash| hash[:full_name]}
        end

        def add_missing_key(metadata_list)
            modified_list = Array[metadata_list].compact.flatten
            modified_list.each{ |hash| hash.store(:namespace_prefix, "") unless hash.has_key?(:namespace_prefix) }
        end

        def format_parent_tree_nodes(api_crud_info, metadata_list)
            if api_crud_info[:api_readable]
                children = true
            else
                children = false
            end
            parent_nodes = []
            metadata_list.each do |hash|
                parent_nodes << {:id => hash[:full_name], :parent => "#", :text => "<b>" + hash[:full_name].to_s + "<b>", :children => children }
            end
            parent_nodes
        end

        def parse_hash(hashes, parent)
            @result = []
            hashes.each do |k, v|
                if v.is_a?(Hash)
                    remodel(get_id(parent, k), parent, key_text(k), false)
                    parse_child(get_id(parent, k), v)
                elsif v.is_a?(Array)
                    remodel(get_id(parent, k), parent, key_text(k), false)
                    v.each_with_index do |val, idx|
                        id = get_id(parent, k, idx)
                        remodel(id, get_id(parent, k), key_text(k, idx), false)
                        parse_child(id, val, idx)
                    end
                else
                    key_id = get_id(parent, k)
                    value_id = get_id(key_id, "value")
                    if k == :"@xsi:type"
                        create_value_node(parent, key_id, k, value_id, v, true)
                    else
                        create_value_node(parent, key_id, k, value_id, v)
                    end
                end
            end
            @result
        end

        def parse_child(parent, hash, index = nil)
            hash.each do |k, v|
                if v.is_a?(Hash)
                    id = get_id(parent, k)
                    remodel(id, parent, key_text(k), false)
                    parse_child(id, v, index)
                elsif v.is_a?(Array)
                    if is_hash_array?(v)
                        v.each_with_index do |item, idx|
                            id = get_id(parent, k, idx)
                            remodel(id, parent, key_text(k, idx), false)
                            parse_child(id, item, idx)
                        end
                    else
                        key_id = get_id(parent, k)
                        value_id = get_id(key_id, "value")
                        create_value_node(parent, key_id, k, value_id, v.join(","))
                    end
                else
                    key_id = get_id(parent, k)
                    value_id = get_id(key_id, "value")
                    create_value_node(parent, key_id, k, value_id, v)
                end
            end
        end

        def create_value_node(parent, key_id, key, value_id, value, force_lock_value = false)
            remodel(key_id, parent, key_text(key), false)
            if force_lock_value
                remodel(value_id, key_id, value_text(key_id, value), false, value_path(key_id))
            else
                remodel(value_id, key_id, value_text(key_id, value), true, value_path(key_id))
            end
        end

        def get_id(parent, current, index = nil)
            if index.nil?
                id = parent.to_s + "/" + current.to_s
            else
                id = parent.to_s + "/" + current.to_s + "[" + index.to_s + "]"
            end
        end

        def key_text(key, index = nil)
            if index.nil?
                "<b>" + key.to_s + "</b>"
            else
                "<b>" + key.to_s + " #" + index.to_s + "</b>"
            end
        end

        def value_path(id)
            split_path = id.split("/")
            split_path.shift
            split_path.join(".")
        end
        
        def value_text(id, value)     
            split_path = id.split("/")
            last_element = split_path.reverse.shift
            try_decode(last_element, value, true)
        end

        def remodel(id, parent_id, text, editable, path = nil)
            if path.present?
                data_type = text.class.to_s
            else
                data_type = nil
            end
            
            @result << {
                        :id => id,
                        :parent => parent_id,
                        :text => text.to_s,
                        :li_attr => {:full_name => @full_name, :editable => editable, :path => path, :data_type => data_type}
                        }
        end        
    end
end