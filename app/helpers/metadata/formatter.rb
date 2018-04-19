module Metadata
  module Formatter
  class << self
    attr_reader :display_array
    attr_reader :raw_array

    def parse(hash_array, id)
      @raw_array = []
      @display_array = parse_hash(hash_array, id)
    end

    def get_id(parent, current, index = nil)
      if index.nil?
        parent.to_s + "-" + current.to_s
      else
        parent.to_s + "-" + current.to_s + "-" + index.to_s
      end
    end

    def get_text(key, value = nil)
      if value.nil?
        return "<b>" + key.to_s + "</b>"
      end

      if key.to_s.include?("content") && value.is_a?(Nori::StringWithAttributes)
        text_value = try_encode(value)
      else
        text_value = value
      end
      
      return "<b>" + key.to_s + "</b>: " + text_value.to_s
    end

    def try_encode(value)
      begin
        decoded = Base64.strict_decode64(value).force_encoding('UTF-8')
        ERB::Util.html_escape(decoded).gsub(/\r\n|\r|\n/, "<br />")
      rescue StandardError => ex
        value
      end
    end

    def remodel(id, parent_id, text, key, value, index)
      @raw_array << {key.to_sym => value, :index => index}

      return {
      :id => id,
      :parent => parent_id,
      :text => text
      }
    end

    def is_hash_array?(array)
      array.all?{ |item| item.is_a?(Hash) }
    end
    
    def include_hash?(array)
      array.flatten.any?{ |item| item.is_a?(Hash) }
    end

    def parse_hash(hashes, parent)
      result = []
      hashes.each do |k, v|
        if v.is_a?(Hash)
          if include_hash?(v.values)
            result << remodel(get_id(parent, k), parent, get_text(k), k, nil, nil)
            parse_child(result, get_id(parent, k), v)
          else
            result << remodel(get_id(parent, k), parent, get_text(k, v.values.join(",")), k, v, nil)
          end
          #result << remodel(get_id(parent, k), parent, get_text(k), k, nil, nil)
          #parse_child(result, get_id(parent, k), v)
        elsif v.is_a?(Array)
          result << remodel(get_id(parent, k), parent, get_text(k), k, nil, nil)
          v.each_with_index do |val, idx|
            id = get_id(parent, k, idx)    
            result << remodel(id, get_id(parent, k), get_text(k, idx), k, nil, idx)
            parse_child(result, id, val, idx)
          end
        else
          result << remodel(get_id(parent, k), parent, get_text(k, v), k, v, nil)
        end
      end
      raw_array.each{|hash| Rails.logger.error(hash.to_s) }
      result
    end

    def parse_child(result, parent, hash, index = nil)
      hash.each do |k, v|
        if v.is_a?(Hash)
          id = get_id(parent, k)
          result << remodel(id, parent, get_text(k), k, nil, index)
          parse_child(result, id, v, index)
        elsif v.is_a?(Array)
          if is_hash_array?(v)
            v.each_with_index do |item, idx|
              if item.is_a?(Hash)
                id = get_id(parent, k, idx)
                result << remodel(id, parent, get_text(k, idx), k, nil, idx)
                parse_child(result, id, item, idx)
              else
                # this may be needless
                #result << remodel(get_id(parent, item, idx), parent, get_text(item), k,  v)
              end
            end
          else
            joined_value = v.join(",")
            result << remodel(get_id(parent, k), parent, get_text(k, joined_value), k, joined_value, index)
          end
        else
          result << remodel(get_id(parent, k), parent, get_text(k, v), k, v, index)
        end
        result
      end
    end
  end
  end
end