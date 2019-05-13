require "json"

module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        
        def execute_query(sforce_session, soql)
            if soql.strip.end_with?(";")
                soql.delete!(";");
            end

            query_result = Service::SoapSessionService.call(sforce_session).query(soql)
            #query_result = Service::ToolingClientService.call(sforce_session).query(soql)

            #if query_result.empty?
            if query_result.blank?
               raise StandardError.new("No matched records found")
            end

            parse_query_result(query_result)
        end
 
        def parse_query_result(query_result)
            results = nil
            if query_result.is_a?(Soapforce::QueryResult)
                results = get_results(query_result.raw_result)
            else
                result = Soapforce::QueryResult.new(query_result)
                results = get_results(result.raw_result)
            end
            
            records = []
            results.each do |result|                
                new_record = {}
                record = extract(result[:records])

                record.each do |k,v|
                    
                    if is_reference?(v)
                        new_record.merge!(resolve_reference(k, v))
                    elsif is_child?(v)
                        new_record.merge!(parse_child(k, v))
                    else
                        new_record.merge!({k => v})
                    end

                end
                records << new_record
            end
            records
        end
        
        def is_reference?(value)
            if is_child?(value)
                false
            elsif value.is_a?(Hash) && value.size > 1
                true
            else
                false
            end
        end

        def is_child?(value)
            if value.is_a?(Hash) && (value.has_key?(:records) || value.has_key?("records"))
                true
            else
                false
            end
        end

        def resolve_reference(key, value)
            result = {}
            extract(value).each do | k, v|
                result.merge!(key.to_s + "." + k.to_s => v)
            end
            result
        end

        def parse_child(key,value)
            records = value[:records]
            child_records = Array[records].flatten.map{|record| extract(record)}
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

        def get_results(hash)
            results = []
            records = Array[hash[:records]].flatten
            records.each do |record|
                if record.is_a?(Soapforce::SObject)
                    results << {:records => record.raw_hash}
                else
                    results << {:records => record}
                end
            end
            results
        end
    end
end
