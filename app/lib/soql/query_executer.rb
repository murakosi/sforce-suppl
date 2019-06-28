require "json"

module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        Records = "records"
        Type = "type"

        def execute_query(sforce_session, soql, tooling)
            if soql.strip.end_with?(";")
                soql.delete!(";");
            end
            
            params = sforce_session.merge({:tag_style => :raw})
            
            if tooling
                query_result = Service::ToolingClientService.call(params).query(soql)
            else
                query_result = Service::SoapSessionService.call(params).query(soql)
            end

            if query_result.nil? || query_result.blank? || !query_result.has_key?(Records)
               raise StandardError.new("No matched records found")
            end

            @sobject_type = ""
            @check_keys = []

            preprare_check_key(soql)            

            records = parse_query_result(query_result)

            {:sobject => @sobject_type, :records => records, :column_options => generate_column_options}
        end
 
        def parse_query_result(query_result)

            records = []            

            results = query_result[Records]
            
            if results.is_a?(Hash)
                results = [results]
            end
            
            results.each do |result|                

                if result.has_key?(Type)
                    @sobject_type = result[Type]
                end
                
                record = {}                
                field_count = 0
                
                extract(result).each do |k,v|
                    
                    if is_reference?(k, v)
                        record.merge!(resolve_reference(k, v))
                    elsif is_child?(v)
                        record.merge!(parse_child(k, v))
                    else
                        if @check_keys.include?(k.to_s.upcase)
                            p k
                            p v
                            record.merge!({k => v})
                        else
                            record.merge!({@check_keys[field_count] => nil})
                        end
                    end
                    
                    field_count += 1
                end
                records << record
            end

            format_records(records)
        end

        def preprare_check_key(soql)
            start_markerstring = "select"
            end_markerstring = "from"

            chekc_key_string = soql[/#{start_markerstring}(.*?)#{end_markerstring}/mi, 1].gsub(/\s+/, '').strip
            if !chekc_key_string.nil?
                @check_keys = chekc_key_string.split(",").map{|str| str.upcase}.reject{|str| str.start_with?("(")}
            end
        end

        def format_records(raw_records)            
            records = []
            max_size_hash = raw_records.max{|h1, h2| h1.size <=> h2.size}
            @model_hash = max_size_hash.map{|k,v| [k,nil]}.to_h

            raw_records.each do | hash |
                records << @model_hash.merge(hash)
            end
            records
        end

        def generate_column_options
            #column_options = [{:type => "checkbox", :readOnly => false, :className => "htCenter htMiddle"}]
            column_options = []
            updatable = @model_hash.has_key?(:id) || @model_hash.has_key?("Id")
            
            @model_hash.each do |k,v|
                if !updatable
                    column_options << {:readOnly => true, :type => "text"}
                elsif k.to_s.upcase == "ID" || k.to_s.include?(".")
                    column_options << {:readOnly => true, :type => "text"}
                else
                    column_options << {:readOnly => false, :type => "text"}
                end
            end

            column_options
        end
        
        def is_reference?(key, value)
            if is_child?(value)
                false
            elsif value.is_a?(Hash) && value.size > 1
                true
            else
                false
            end
        end

        def is_child?(value)
            if value.is_a?(Hash) && (value.has_key?(:records) || value.has_key?(Records))
                true
            else
                false
            end
        end

        def resolve_reference(key, value)
            result = {}

            if !value.nil?
                extract(value).each do | k, v|
                    result.merge!(key.to_s + "." + k.to_s => v)
                end
            end

            result
        end

        def parse_child(key,value)
            records = value[Records]
            child_records = Array[records].flatten.map{|record| extract(record)}
            a = JSON.generate(child_records)
            p a.class
            {key => JSON.generate(child_records)}
        end

        def extract(record)
            result = {}
            record.each do |k,v|
                next if skip?(k, v)
                result.merge!(remove_duplicate_id(k, v))
            end
            result
        end

        def skip?(key, value)
            if Exclude_key_names.include?(key.to_s.downcase)
                return true
            end

            if key.to_s.downcase == "id" && value.nil?
                return true
            end

            return false
        end

        def remove_duplicate_id(key, value)            
            if key.to_s.downcase == "id" && value.is_a?(Array)
                {key => value.first}
            else
                {key => value}
            end
        end

    end
end
