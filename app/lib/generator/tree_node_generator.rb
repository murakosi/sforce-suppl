module Generator
	module TreeNodeGenerator

        def generate_parent_nodes(api_crud_info, metadata_list)
            if api_crud_info[:api_readable]
                has_children = true
            else
                has_children = false
            end
            parent_nodes = []
            metadata_list.each do |hash|
                parent_nodes << parent_node(hash, has_children)
            end
            parent_nodes
        end

        def parent_node(hash, has_children)
        	{
        		:id => hash[:full_name],
        		:parent => "#",
        		:text => "<b>" + hash[:full_name].to_s + "<b>",
        		:children => has_children,
        		:li_attr => {:editable => false} 
        	}
        end

        def generate_nodes(full_name, read_result, type_info)
        	@full_name = full_name
            if @full_name.include?("/")
                @path_full_name = true
            else
                @path_full_name = false
            end
        	@type_info = tree_type_info(type_info)
        	parse_read_result(read_result, full_name)
        end

        def tree_type_info(type_fields)
            types = {}
            enums = Metadata::EnumProvider.enums
            
            type_fields.each do |type_field|
                hash = Hash[*type_field.values]
                name = type_field.keys.first
                soap_type = hash[:soap_type].to_s.camelize(:lower)               

                if hash[:soap_type] == "boolean"
                    types[name] = {:is_picklist => true, :picklist_source => ["true", "false"]}
                elsif hash.has_key?(:picklist_values)
                    types[name] = {:is_picklist => true, :picklist_source => hash[:picklist_values].map{|hash| hash[:value]}}
                elsif enums.has_key?(soap_type)
                    types[name] = {:is_picklist => true, :picklist_source => enums[soap_type]}
                else
                    types[name] = {:is_picklist => false}
                end
            end

            types
        end

        def parse_read_result(hashes, parent)
            @result = []
            hashes.each do |k, v|
                if v.is_a?(Hash)
                    push_result(get_id(parent, k), parent, key_text(k), false)
                    parse_child(get_id(parent, k), v)
                elsif v.is_a?(Array)
                    push_result(get_id(parent, k), parent, key_text(k), false)
                    v.each_with_index do |val, idx|
                        id = get_id(parent, k, idx)
                        push_result(id, get_id(parent, k), key_text(k, idx), false)
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
                    push_result(id, parent, key_text(k), false)
                    parse_child(id, v, index)
                elsif v.is_a?(Array)
                    if is_hash_array?(v)
                        v.each_with_index do |item, idx|
                            id = get_id(parent, k, idx)
                            push_result(id, parent, key_text(k, idx), false)
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
            push_result(key_id, parent, key_text(key), false)
            if force_lock_value
                push_result(value_id, key_id, value_text(key_id, value), false, value_path(key_id))
            else
                push_result(value_id, key_id, value_text(key_id, value), true, value_path(key_id))
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
            if @path_full_name
                split_path.shift
            end
            split_path.join(".")
        end
        
        def value_text(id, value)     
            split_path = id.split("/")
            last_element = split_path.reverse.shift
            try_decode(last_element, value, true)
        end

        def value_field_name(path)
            split_path = path.split(".")
            split_path.map{|str| str.gsub(/[\[[0-9]\]]/,"").camelize(:lower)}.join(".")
        end

        def picklist_info(field)
            picklist = @type_info[field]
            if picklist.nil?
                {}
            else
                picklist
            end
        end

        def data_type(value)
            if value.is_a?(Nori::StringWithAttributes)
                "String"
            else
                value.class.to_s
            end
        end

        def push_result(id, parent_id, text, editable, path = nil)
            if path.present?
                data_type = data_type(text)
                picklist = picklist_info(value_field_name(path))
            else
                data_type = nil
                picklist = {}
            end

            li_attr = {:full_name => @full_name, :editable => editable, :path => path, :data_type => data_type}.merge!(picklist)           
            
            @result << {
                        :id => id,
                        :parent => parent_id,
                        :text => text.to_s,
                        :li_attr => li_attr
                        }
        end

	end
end