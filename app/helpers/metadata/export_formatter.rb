module Metadata
    module ExportFormatter

        def format_for_export(hashes)
            @value_store = ValueStore.new
            hashes.each do | k, v |
                if v.is_a?(Hash) || v.is_a?(Array)
                    parse_deep(v, k, true)
                else
                    @value_store.set_value(k, v)
                end
            end

            recreate
        end

        def parse_deep(item, token, add_key)
            if item.is_a?(Hash)
                item.each do | k, v |
                    access_key = (token.to_s + "_" + k.to_s).to_sym

                    if v.is_a?(Hash)
                        flattened_hash = HashFlatter.flat(v)                       
                        flattened_hash.each do | fkey, fval |
                            access_key2 = (access_key.to_s + "_" + fkey.to_s).to_sym
                            @value_store.set_value(access_key2, fval)
                        end
                    else
                        @value_store.set_value(access_key, v)
                    end
                end
            elsif item.is_a?(Array)
                item.each_with_index do | element, index|
                    access_key = (token.to_s + "/" + index.to_s + "/").to_sym

                    flattened_hash = HashFlatter.flat(element)
                    flattened_hash.each do | fkey, fval |
                        access_key2 = (access_key.to_s + fkey.to_s).to_sym
                        @value_store.set_value(access_key2, fval)
                    end
                end
            end
        end

        def recreate
            keys = {}
            value_index = 0
            key_array = []

            @value_store.values.each do | key, value |

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
                value_hash = {:index => value_index, :value => value}
                if keys.has_key?(access_key)
                    keys[access_key].push(value_hash)
                else
                    keys[access_key] = [value_hash]
                end
            end

            keys
        end

        class ValueStore

            attr_reader :values

            def initialize()
                @values = Hash.new
            end

            def set_value(access_key, hash)
                if @values.has_key?(access_key)
                    @values[access_key].merge!(hash)
                else
                    if hash.nil?
                        @values.store(access_key, {})
                    else
                        @values.store(access_key, hash)
                    end
                end
            end
        end
    end
end