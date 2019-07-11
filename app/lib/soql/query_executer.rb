require "json"

module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        Records = "records"
        Type = "type"
        Id = "ID"
        From_with_space = " from "
        Select_with_space = "select "
        Select = "select"
        Where_with_space = " where "

        def execute_query(sforce_session, soql, tooling, query_all)
            if soql.strip.end_with?(";")
                soql.delete!(";");
            end
            
            params = sforce_session.merge({:tag_style => :raw})
            
            if tooling
                query_result = Service::ToolingClientService.call(params).query(soql)
            else
                if query_all
                    query_result = Service::SoapSessionService.call(params).query_all(soql)
                else
                    query_result = Service::SoapSessionService.call(params).query(soql)
                end
            end

            if query_result.nil? || query_result.blank? || !query_result.has_key?(Records)
               raise StandardError.new("No matched records found")
            end

            @sobject_type = nil
            @query_fields = {}
            parse_query_fields(soql)
            @check_keys = @query_fields.keys
            id_column_index = @query_fields.keys.index(Id)

            records = parse_query_result(query_result).map{|hash| hash.slice(*@query_fields.keys)}

            {:sobject => @sobject_type, :records => records, :column_options => generate_column_options, :id_column_index => id_column_index}
        end
 
        def parse_query_result(query_result)

            records = []            

            results = query_result[Records]
            
            if results.is_a?(Hash)
                results = [results]
            end

            results.each do |result|                

                if @sobject_type.nil? && result.has_key?(Type)
                    @sobject_type = result[Type]
                end
                
                #record = {"" => false}
                record = {}

                field_count = 0
                
                extract(result).each do |k,v|
                    if is_reference?(k, v)
                        record.merge!(resolve_reference(k, v))
                    elsif is_child?(v)
                        record.merge!(parse_child(k, v))
                    else
                        if @query_fields.has_key?(k.to_s.upcase)
                            record.merge!(get_hash(k, v))
                        else
                            record.merge!(get_hash(@query_fields.keys[field_count], nil))
                        end
                    end
                    
                    field_count += 1
                end
                records << record
            end

            records
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
            if value.is_a?(Hash) && value.has_key?(Records)
                true
            else
                false
            end
        end

        def resolve_reference(key, value)
            if value.nil?
                return {}
            end

            @reference = {}
            resolve_ref_deep(key, extract(value))
            @reference
        end

        def resolve_ref_deep(key, value)
            value.each do | k, v|
                if v.is_a?(Hash)
                    resolve_ref_deep(key.to_s + "." + k.to_s, extract(v))
                else
                    @reference.merge!(get_hash(key.to_s + "." + k.to_s, v))
                end
            end
        end

        def parse_child(key,value)
            records = value[Records]
            child_records = []
            Array[records].flatten.each do |record|
            	@children = {}
            	parse_deep_child(record)
            	child_records << @children
            end
            
            #child_records = Array[records].flatten.map{|record| extract(record)}
            get_hash(key, JSON.generate(child_records))
        end

        def parse_deep_child(record, key = nil)
            record.each do |k, v|
            	next if skip?(k, v)
                if v.is_a?(Hash)
                    parse_deep_child(v, k)
                else
                	if key.nil?
                    	@children.merge!({k=>v})
                    else
                    	@children.merge!({key => {k => v} })
                    end
                end
            end

        end

        def extract(record)
            result = {}
            record.each do |k,v|
                next if skip?(k, v)
                result.merge!(remove_duplicate_id(k, v))                
            end
            result
        end

        def get_hash(key, value)
            {key.to_s.upcase => value}
        end
        
        def skip?(key, value)
            if Exclude_key_names.include?(key.to_s.downcase)
                return true
            end

            if key.to_s.upcase == Id && value.nil?
                return true
            end

            return false
        end

        def remove_duplicate_id(key, value)            
            if key.to_s.upcase == Id && value.is_a?(Array)
                {key => value.first}
            else
                {key => value}
            end
        end

        def parse_query_fields(soql)

            #chekc_key_string = soql[/#{start_markerstring}(.*?)#{end_markerstring}/mi, 1].gsub(/\s+/, '').strip
            fields = []
            soql = soql.gsub(/(\r|\n|\r\n)/mi, ' ')

            start_position = soql.index(Select_with_space) + Select.size
            end_position = soql.rindex(From_with_space) - 1
            soql = soql[start_position..end_position]

            sub_queries = soql.scan(/\((.*?)\)/mi).flatten

            main_soql = soql.gsub(/\((.*?)\)/mi, "").gsub(/\s+/, '').strip

            main_soql.split(",").reject(&:empty?).each{|str| generate_query_fields(str)}

            if !sub_queries.nil?
                sub_queries.each{|str| generate_query_fields(str[/#{From_with_space}(.*?)(#{Where_with_space}|$)/mi, 1], :children)}
            end

            upcase_soql = soql.upcase

            #@check_keys.flatten!.sort! {|a, b| upcase_soql.index(a) <=> upcase_soql.index(b) }
            field_type_array = @query_fields.sort{|(k1, v1), (k2, v2)| upcase_soql.index(k1) <=> upcase_soql.index(k2) }
            @query_fields = Hash[*field_type_array.flatten(1)]
        end

        def generate_query_fields(field_name, type = nil)
            field_name.upcase!
            if !type.nil?
                @query_fields[field_name] = type
            elsif field_name == Id
                @query_fields[field_name] = :id
            elsif field_name.include?(".")
                @query_fields[field_name] = :reference
            else
                @query_fields[field_name] = :text
            end
            
        end
        
        def generate_column_options
            #column_options = [{:type => "checkbox", :readOnly => false, :className => "htCenter htMiddle"}]
            column_options = []
            updatable = @query_fields.has_key?(Id)

            @query_fields.each do |k,v|
                if !updatable
                    column_options << {:readOnly => true, :type => "text"}
                elsif v == :id || v == :children || v == :reference
                    column_options << {:readOnly => true, :type => "text"}
                else
                    column_options << {:readOnly => false, :type => "text"}
                end
            end

            column_options
        end
    end

end
