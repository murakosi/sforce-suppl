require "json"

module Soql

    class QueryExecuter
    class << self

        Exclude_key_names = ["@xsi:type", "type"]
        Records = "records"
        Type = "type"
        Id = "ID"

        def execute_query(sforce_session, soql, tooling, query_all)
            if soql.strip.include?(";")
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

            get_parsed_query_result(soql, query_result)
        end

        def get_parsed_query_result(soql, query_result)
            @sobject_type = nil
            @query_fields = {}
            if parse_soql(soql)
                @query_keys = @query_fields.keys
                @executed_soql = soql
                @record_count = query_result["size"]
            else
                @query_keys = @query_fields.keys
                @executed_soql = soql
                @record_count = 1
                query_result.store(Records, [{"COUNT()" => query_result["size"]}])
            end
            records = []

            if query_result.nil? || query_result.blank? || !query_result.has_key?(Records)
                @query_result = get_response_hash(records)
            else
                records = parse_query_result(query_result).map{|hash| hash.slice(*@query_keys)}
                @query_result = get_response_hash(records)
            end
  
        end

        def get_response_hash(records)
            {
                :soql => @executed_soql,
                :sobject => @sobject_type,
                :records => records,
                :record_count => @record_count,
                :columns => @query_keys,
                :column_options => generate_column_options,
                :id_column_index => @query_keys.index(Id)
            }            
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
                
                extract(result).each do |k,v|

                    if is_reference?(k, v)
                        record.merge!(resolve_reference(k, v))
                    elsif is_child?(v)
                        record.merge!(parse_child(k, v))
                    else
                        if @query_fields.has_key?(k.to_s.upcase)
                            record.merge!(get_hash(k, v))
                        end
                    end
                    
                end

                @query_keys.each do | key |
                    if !record.has_key?(key)
                        record.merge!( {key => nil} )
                    end
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
            resolve_deep_reference(key, extract(value))
            @reference
        end

        def resolve_deep_reference(key, value)
            value.each do | k, v|
                if v.is_a?(Hash)
                    resolve_deep_reference(key.to_s + "." + k.to_s, extract(v))
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


        def parse_soql(soql)
            expr_count = 0
            parse_result = Soql::SoqlParser.parse(soql)

            @sobject_type = parse_result[:objects].first[:object_name]

            parse_result[:fields].each do |field|
                if field.has_key?(:sub_query)
                    sub_query = field[:sub_query]
                    @query_fields[sub_query[:object_name]] = :children
                elsif field.has_key?(:function)
                    function = field[:function]
                    if function == :count_all
                        @query_fields["COUNT()"] = :reference
                        return false
                    elsif function.nil?
                        @query_fields["EXPR" + expr_count.to_s] = :reference
                        expr_count += 1
                    else
                        @query_fields[field_name] = :reference
                    end
                else
                    field_name = field[:name]
                    if field_name == Id
                        @query_fields[field_name] = :id
                    elsif field_name.include?(".")
                        @query_fields[field_name] = :reference
                    else
                        @query_fields[field_name] = :text
                    end
                end
            end
            
            return true
        end
=begin
        def parse_query_fields(soql)

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
=end        
        def generate_column_options
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
end
