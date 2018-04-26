module Metadata
    class MetadataStore
        
        attr_reader :key_store
        attr_reader :csv_header
        #attr_reader :values

        def initialize
            @csv_header = ["access_key","index", "value"]
        end

        def stored?
            @key_store.present?
        end

        def recreate
            keys = {}
            value_index = 0
            key_array = []

            @key_store.values.each do | key, value |

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

            @key_store.store(keys)
        end

        def parse(hashes)
            @key_store = KeyStore.new(hashes[:"@xsi:type"])
            hashes.each do | k, v |
                if v.is_a?(Hash) || v.is_a?(Array)
                    parse_deep(v, k, true)
                else
                    @key_store.set_value(k, v)
                end
            end

            recreate
        end

        def parse_deep(item, token, add_key)
            if item.is_a?(Hash)
                item.each do | k, v |
                    if !add_key
                        @key_store.set_value(token, {k => v})
                    else
                        access_key = (token.to_s + "_" + k.to_s).to_sym
                        @key_store.set_value(access_key, v)
                    end
                end
            elsif item.is_a?(Array)
                item.each_with_index do | element, index|

                    #access_key = token.to_sym
                    access_key = (token.to_s + "/" + index.to_s + "/").to_sym
#=begin
                    #------------- separate
                    flattened_hash = HashFlatter.flat(element)
                    
                    flattened_hash.each do | fkey, fval |
                        access_key2 = (access_key.to_s + fkey.to_s).to_sym
                        @key_store.set_value(access_key2, fval)
                    end
#=end
                    #-------- grouping
=begin                    
                    element.each do |k2, v2|
                        if v2.is_a?(Hash)
                            flattened_hash = HashFlatter.flat(v2)
                            parse_deep(flattened_hash, access_key, false)
                        else
                            @keys.set_value(access_key, {k2 => v2})
                        end
                    end
=end                    
                end
            end
        end

        class KeyStore

            attr_reader :xsi_type
            attr_reader :keys
            attr_reader :values

            def initialize(xsi_type)
                @xsi_type = xsi_type
                @keys = Hash.new
                @values = Hash.new
            end
=begin
            def store(top_key, key)
                if @keys.has_key?(top_key)
                    @keys[top_key].push(key)
                else
                    @keys.store(top_key, [key])
                end
            end
=end
            def store(keys)
                @keys = keys
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

        class ValueStore
            
            attr_reader :values

            def initialize
                @values = Hash.new
            end

            def store(access_key, hash = nil)
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