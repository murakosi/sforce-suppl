module Metadata
    class MappingFormatter
    class << self
        include Metadata::FormatUtils

        def format(full_name, result)

            @parsed_hash = {}
            result.each do | k, v |
                if v.is_a?(Hash) || v.is_a?(Array)
                    parse_deep(k, v)
                else
                    store_hash(k, v)
                end
            end
            rebuild_hash()
        end

        def parse_deep(token, item)
            if item.is_a?(Hash)
                item.each do | k, v |
                    access_key = (token.to_s + "_" + k.to_s).to_sym

                    if v.is_a?(Hash)
                        flattened_hash = Metadata::HashFlatter.flat(v)                
                        flattened_hash.each do | fkey, fval |
                            access_key2 = (access_key.to_s + "_" + fkey.to_s).to_sym
                            store_hash(access_key2, fval)
                        end
                    elsif is_hash_array?(v)
                        parse_deep(access_key, v)
                    else
                        store_hash(access_key, v)
                    end
                end
            elsif item.is_a?(Array)
                item.each_with_index do | element, index|

                    access_key = (token.to_s + "/" + index.to_s + "/").to_sym

                    flattened_hash = Metadata::HashFlatter.flat(element)
                    flattened_hash.each do | fkey, fval |
                        access_key2 = (access_key.to_s + fkey.to_s).to_sym
                        store_hash(access_key2, fval)
                    end
                end
            end
        end

        def store_hash(access_key, hash)
            if @parsed_hash.has_key?(access_key)
                @parsed_hash[access_key].merge!(hash)
            else
                if hash.nil?
                    @parsed_hash.store(access_key, {})
                else
                    @parsed_hash.store(access_key, hash)
                end
            end
        end

        def rebuild_hash
            keys = {}
            value_index = 0
            key_array = []

            @parsed_hash.each do | key, value |

                value_index = 0
                key_array.clear

                key.to_s.split("/").each do | str |
                    begin
                        Integer(str)
                        value_index = str.to_i
                    rescue
                        key_array << str
                    end
                end

                access_key = key_array.join("_").to_sym
                value_hash = {:index => value_index, :value => try_decode(key, value)}

                if keys.has_key?(access_key)
                    keys[access_key].push(value_hash)
                else
                    keys[access_key] = [value_hash]
                end
            end

            keys
        end
    end
    end
end