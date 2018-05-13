module Metadata
    module DisplayFormatter
    include Formatter

        def format_for_display(hash_array, id)
            @display_array = parse_hash(hash_array, id)
        #=begin
            #puts @metadata_store.key_store.xsi_type
            #puts "keys!!!!!!!!!!!!!"
            #puts @metadata_store.key_store.keys
            #puts "vlus!!!!!!!!!!"
            #puts @metadata_store.key_store.values
        #=end     
            @display_array
        end

        def get_tree_parent_nodes(metadata_list)
            parent_nodes = []
            metadata_list.each do |hash|
                parent_nodes << {:id => hash[:full_name], :parent => "#", :text => "<b>" + hash[:full_name].to_s + "<b>", :children => true }
            end
            parent_nodes
        end

        def parse_hash(hashes, parent)
            result = []
            hashes.each do |k, v|
                if v.is_a?(Hash)
                    result << remodel(get_id(parent, k), parent, get_text(k), k, v, nil)
                    parse_child(result, get_id(parent, k), v)
                elsif v.is_a?(Array)
                    result << remodel(get_id(parent, k), parent, get_text(k), k, v, nil)
                    v.each_with_index do |val, idx|
                        id = get_id(parent, k, idx)
                        result << remodel(id, get_id(parent, k), get_text(k, idx), k, val, idx)
                        parse_child(result, id, val, idx)
                    end
                else
                    result << remodel(get_id(parent, k), parent, get_text(k, v), k, v, nil)
                end
            end
            result
        end

        def parse_child(result, parent, hash, index = nil)
            hash.each do |k, v|
                if v.is_a?(Hash)
                    id = get_id(parent, k)
                    result << remodel(id, parent, get_text(k), k, v, index)
                    parse_child(result, id, v, index)
                elsif v.is_a?(Array)
                    if is_hash_array?(v)
                        v.each_with_index do |item, idx|
                            if item.is_a?(Hash)
                                id = get_id(parent, k, idx)
                                result << remodel(id, parent, get_text(k, idx), k, item, idx)
                                parse_child(result, id, item, idx)
                            else
                                result << remodel(get_id(parent, item, idx), parent, get_text(item), k,  v)
                            end
                        end
                    else
                        joined_value = v.join(",")
                        result << remodel(get_id(parent, k), parent, get_text(k, joined_value), k, v, index)
                    end
                else
                    result << remodel(get_id(parent, k), parent, get_text(k, v), k, v, index)
                end
                result
            end
        end

        def get_id(parent, current, index = nil)
            if index.nil?
                parent.to_s + "_" + current.to_s
            else
                parent.to_s + "_" + current.to_s + "_" + index.to_s
            end
        end

        def get_text(key, value = nil)     
            if value.nil?
                return "<b>" + key.to_s + "</b>"
            end

            "<b>" + key.to_s + "</b>: " + try_decode(key, value, true).to_s#text_value.to_s
        end

        def remodel(id, parent_id, text, key, value, index)
            {
            :id => id,
            :parent => parent_id,
            :text => text
            }
        end
    end
end