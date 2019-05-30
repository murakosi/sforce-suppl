require "json"

module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        Reference_suffix = "__r"

        def execute_query(sforce_session, soql, tooling)
            if soql.strip.end_with?(";")
                soql.delete!(";");
            end
            
            if tooling
                query_result = Service::ToolingClientService.call(sforce_session).query(soql)
            else
                query_result = Service::SoapSessionService.call(sforce_session).query(soql)
            end

            if query_result.nil? || query_result.blank? || !query_result.has_key?(:records)
               raise StandardError.new("No matched records found")
            end

            @sobject_type = nil

            records = parse_query_result(query_result)

            {:sobject => @sobject_type, :records => records}
        end
 
        def parse_query_result(query_result)

            records = []

            results = query_result[:records]
            
            if results.is_a?(Hash)
                results = [results]
            end
            
            results.each do |result|                

                if result.has_key?(:type)
                    @sobject_type = result[:type]
                end
                
                record = {}

                extract(result).each do |k,v|
                    
                    if is_reference?(k, v)
                        record.merge!(resolve_reference(k, v))
                    elsif is_child?(v)
                        record.merge!(parse_child(k, v))
                    else
                        record.merge!({k => v})
                    end

                end
                records << record
            end

            #records
            format_records(records)
        end
        
        #def get_results(hash)
        #    results = []
        #    records = Array[hash[:records]].flatten
        #    records.each do |record|
        #        if record.is_a?(Soapforce::SObject)
        #            results << {:records => record.raw_hash}
        #        else
        #            results << {:records => record}
        #        end
        #    end
        #    results
        #end

        def format_records(raw_records)
            records = []
            max_size_hash = raw_records.max{|hash| hash.size}
            model_hash = max_size_hash.map{|k,v| [k,nil]}.to_h

            raw_records.each do | hash |
                records << model_hash.merge(hash)
            end
            records
        end

        def is_reference?(key, value)
            if is_child?(value)
                false
            #elsif value.is_a?(Hash) && value.size > 1
            elsif key.to_s.end_with?(Reference_suffix)
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

            if !value.nil?
                extract(value).each do | k, v|
                    result.merge!(key.to_s + "." + k.to_s => v)
                end
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

    end
end
