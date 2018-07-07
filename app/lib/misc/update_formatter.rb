module Metadata
    class UpdateFormatter
    class << self
        include Utils::FormatUtils

        def format(full_name, result)
            @full_name = full_name
            parse_hash(result, full_name)
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
end