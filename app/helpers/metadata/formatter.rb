module Metadata
  module Formatter
  class << self
    attr_reader :display_array


    def metadata_store
      @metadata_store
    end

    Mapping = [
        {:full_name => {:r => 7, :c=>3}},
        {:active => {:r => 8, :c=>17}},
        {:allow_recall => {:r => 10, :c=>26}},
        {:allowed_submitters_type => {:r => 10, :c=>37}},
        {:approval_step_assigned_approver_approver_name => {:r => 28, :c=>35}},
        {:approval_step_entry_criteria_criteria_items_field => {:r => 31, :c=>21}},
        #{:approval_step_entry_criteria_criteria_items_operation => {:r => 31, :c=>30}},
        #{:approval_step_entry_criteria_criteria_items_value => {:r => 31, :c=>40}},
        {:approval_step_label => {:r => 28, :c=>21}},
        {:approval_step_reject_behavior_type => {:r => 28, :c=>49}},
        {:email_template => {:r => 10, :c=>44}},
        {:entry_criteria_criteria_items => {:r => 8, :c=>19}},
        {:final_approval_record_lock => {:r => 57, :c=>20}},
        {:final_rejection_record_lock => {:r => 60, :c=>20}},
        {:label => {:r => 7, :c=>9}},
        {:next_automated_approver_user_hierarchy_field => {:r => 8, :c=>44}},
        {:record_editability => {:r => 10, :c=>19}}
    ]

    def mapping
      Mapping
    end

    def parse(hash_array, id)
      @metadata_store = Metadata::MetadataStore.new
      @metadata_store.parse(hash_array)
      @path = []
      @key = nil
      @parent_full_name = id
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

    def get_id(parent, current, index = nil)
      if index.nil?
        id = parent.to_s + "_" + current.to_s
      else
        id = parent.to_s + "_" + current.to_s + "_" + index.to_s
      end

      #@path.push(parent.to_s + "/" + current.to_s + "[" + index.to_s + "]")
      id
    end

    def get_text(key, value = nil)
      
      if value.nil?
        text = "<b>" + key.to_s + "</b>"
      else
        if key.to_s.include?("content") && value.is_a?(Nori::StringWithAttributes)
          text_value = try_encode(value)
        else
          text_value = value
        end
        
        text = "<b>" + key.to_s + "</b>: " + text_value.to_s
      end
=begin
      if @key.nil?
        @key = key.to_s
        @path.push("key:" + key.to_s)
        @path.push("value:" + value.to_s)
        @path.push("path:" + @key)
      else
        @key = @key + "/" + key.to_s
        @path.push("key:" + key.to_s)
        @path.push("value:" + value.to_s)
        @path.push("path:" + @key)
      end
=end      
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
      {
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