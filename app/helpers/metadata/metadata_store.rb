module Metadata
    class MetadataStore
        
        attr_reader :keys
        #attr_reader :values

        def initialize
            @keys = KeyStore.new
            #@values = ValueStore.new
        end

        def parse(hashes)
            hashes.each do | k, v |
                if v.is_a?(Hash) || v.is_a?(Array)
                    parse_deep(v, k, true)
                else
                    @keys.store(k, k)
                    @keys.set_value(k, v)
                end
            end
        end

        def parse_deep(item, token, add_key)
            if item.is_a?(Hash)
                item.each do | k, v |
                    if !add_key
                        @keys.store(token, token) if add_key
                        @keys.set_value(token, {k => v})
                    else
                        access_key = (token.to_s + "_" + k.to_s).to_sym
                        @keys.set_value(access_key, v)
                    end
                end
            elsif item.is_a?(Array)
                item.each_with_index do | element, index|

                    access_key = token.to_sym#(token.to_s + "_no_" + index.to_s).to_sym
                    @keys.store(token, access_key) if add_key
  
                    element.each do |k2, v2|
                        if v2.is_a?(Hash)
                            flattened_hash = HashFlatter.flat(v2)
                            parse_deep(flattened_hash, access_key, false)
                        else
                            @keys.set_value(access_key, {k2 => v2})
                        end
                    end
                end
            end
        end

        class KeyStore

            attr_reader :keys
            attr_reader :values

            def initialize
                @keys = Hash.new
                @values = Hash.new
            end

            def store(top_key, key)
                if @keys.has_key?(top_key)
                    @keys[top_key].push(key)
                else
                    @keys.store(top_key, [key])
                end
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