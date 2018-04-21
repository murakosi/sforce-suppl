module Metadata
    class MetadataStore
        
        attr_reader :keys
        attr_reader :values

        def initialize
            @keys = KeyStore.new
            @values = ValueStore.new
            @index = 0
            @flat = false
        end

        def parse(hashes)
            hashes.each do | k, v |
                if v.is_a?(Hash) || v.is_a?(Array)
                    parse_deep(v, k, true)
                else
                    @keys.add(k, k)
                    #puts "lev0:" + k.to_s
                    @values.add(k, v)
                end
            end
        end

        def parse_deep(item, token, add_key)
            if item.is_a?(Hash)
                item.each do | k, v |
                    #if v.is_a?(Hash)
                        #puts "lev1:" + token.to_s + "@" + k.to_s
                        #nhash = HashFlatter.flat({token.to_s + "_" + k.to_s => v)
                        #@keys.add(token, token) if add_key
                        #@values.add(token, {k => v})
                        if !add_key
                            @keys.add(token, token) if add_key
                            @values.add(token, {k => v})
                        else
                            access_key = (token.to_s + "_" + k.to_s).to_sym
                            @keys.add(token, access_key)
                            @values.add(access_key, v)
                        end
                    #end
                end
            elsif item.is_a?(Array)
                #akeysym = (token.to_s + "#" + @index.to_s).to_sym
                item.each_with_index do | element, index|
                akeysym = (token.to_s + "_no_" + index.to_s).to_sym
                @keys.add(token, akeysym) if add_key
                #item.each do | e |
                element.each do | e |
                    e.each do |k2, v2|
                        if v2.is_a?(Hash)
                            nhash = HashFlatter.flat(v2)
                            #puts "lev2" + nhash.to_s
                            parse_deep(nhash, akeysym, false)
                        else
                            #puts "lev3:" + k2.to_s
                            @values.add(akeysym, {k2 => v2})
                        end
                    end
                end
                end
            else
                raise StandardError.new("error error error")
            end
        end

        def dest(arr, akey = nil)
            #puts arr
            arr.each do | k, v |
                #if hash.keys.length == 1
                #    access_key = if access_key.nil? then hash.keys.first else akey
                #    value = hash
                #    @keys.add(access_key, access_key)
                #    @values.add(access_key, value)
                #elsif is_hash_with_hash(hash)
                #    access_key = if access_key.nil? then hash.keys.first else akey
                #    value = hash
                #    @keys.add(access_key, access_key)
                #    @values.add(access_key, value)
                #elsif is_hash_with_array(hash)
                #    access_key = if access_key.nil? then hash.keys.first else akey
                #    value = hash
                #    @keys.add(access_key, access_key)
                #    @values.add(access_key, value)
                
                if v.is_a?(Array)
                    v.each do | child |
                        access_key = k.to_s + "#"
                        @keys.add(k.to_s, access_key)
                        dest(child, access_key)
                    end
                elsif v.is_a?(Hash)
                    access_key = if akey.nil? then k else akey end
                    value = v
                    @keys.add(access_key, access_key)
                    @values.add(access_key, value)
                else
                    access_key = if akey.nil? then k else akey end
                    value = {k => v}
                    @keys.add(access_key, access_key)
                    @values.add(access_key, value)
                end

                
            end
        end

        def store(parent, current, index = nil)
            if current.is_a?(Hash)
                access_key = parent.to_s + "_" + current.keys.join("_")
            elsif current.is_a?(Array)
                access_key = parent.to_s + "_#" +  @index.to_s
                @index += 1
            else
                access_key = parent
            end
            #access_key = get_id(parent, current, index = nil)
            @keys.add(parent, access_key)

            @values.add(access_key, current)
            access_key
        end

        class KeyStore

            attr_reader :keys
            def initialize
                @keys = Hash.new
            end

            def add(top_key, key)
                if @keys.has_key?(top_key)
                    @keys[top_key].push(key)
                else
                    @keys.store(top_key, [key])
                end
            end
        end

        class ValueStore
            
            attr_reader :values

            def initialize
                @values = Hash.new
            end

            def add(access_key, hash = nil)
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