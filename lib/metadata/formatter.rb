module Metadata
    module Formatter
        def try_decode(key, value, escape = false)
            if key.to_s.include?("content") && value.is_a?(Nori::StringWithAttributes)
                begin
                    decoded = Base64.strict_decode64(value).force_encoding('UTF-8')
                    if escape
                        ERB::Util.html_escape(decoded).gsub(/\r\n|\r|\n/, "<br />")
                    else
                        decoded
                    end
                rescue StandardError => ex
                    value
                end
            else
                value
            end
        end

        def is_hash_array?(array)
            if array.is_a?(Array)
                array.all?{ |item| item.is_a?(Hash) }
            else
                false
            end
        end
        
        def include_hash?(array)
            if array.is_a?(Array)
                array.flatten.any?{ |item| item.is_a?(Hash) }
            else
                false
            end            
        end
    end
end