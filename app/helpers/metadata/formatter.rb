module Metadata
  module Formatter
  class << self
    attr_reader :display_array
    #attr_reader :raw_array

    def parse(hash_array, id)
      @meta_store = Metadata::MetadataStore.new
      @meta_store.parse(hash_array)
      @path = []
      @key = String.new
      @display_array = parse_hash(hash_array, id)
#=begin
      #puts "keys!!!!!!!!!!!!!"
      #puts @meta_store.keys.keys
      #puts "vlus!!!!!!!!!!"
      #puts @meta_store.keys.values
      puts @path
#=end     
      @display_array
    end

    def get_id(parent, current, index = nil)
      if index.nil?
        id = parent.to_s + "_" + current.to_s
      else
        id = parent.to_s + "_" + current.to_s + "_" + index.to_s
      end

      #@path.push("parent: " + parent.to_s + " current:" + current.to_s)
      id
    end

    def get_text(key, value = nil)
      
      if value.nil?
        text = "<b>" + key.to_s + "</b>"
      end

      if key.to_s.include?("content") && value.is_a?(Nori::StringWithAttributes)
        text_value = try_encode(value)
      else
        text_value = value
      end
      
      text = "<b>" + key.to_s + "</b>: " + text_value.to_s

      if value.nil?
        @path.push("key:" + key.to_s)
        @key = key.to_s
      else
        @key = @key + "/" + key.to_s
        @path.push("path:" + @key)
        @path.push("value:" + value.to_s)
      end
      text
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
          #if include_hash?(v.values)
            result << remodel(get_id(parent, k), parent, get_text(k), k, v, nil)
            parse_child(result, get_id(parent, k), v)
          #else
          #  result << remodel(get_id(parent, k), parent, get_text(k, v.values.join(",")), k, v, nil)
          #end
          #result << remodel(get_id(parent, k), parent, get_text(k), k, nil, nil)
          #parse_child(result, get_id(parent, k), v)
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
                #puts "this may be needless"
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
  end
  end
end