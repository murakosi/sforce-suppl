require "json"

module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        
        def execute_query(sforce_session, soql)
            if soql.end_with?(";")
                soql = soql
            end

            query_result = Service::SoapSessionService.call(sforce_session).query(soql)

            if query_result.empty?
               raise StandardError.new("No matched records found")
            end

            parse_query_result(query_result)
        end
 
        def parse_query_result(query_result)
            results = get_results(query_result.raw_result)
            records = []
            results.each do |result|
                reference_record = {}
                record = extract(result[:records])
                record.each do |k,v|
                    
                    if v.is_a?(Hash) && v.size > 1
                        reference_record = resolve_reference(k, v)
                        record.delete(k)
                    end

                    if v.is_a?(Hash) && (v.has_key?(:records) || v.has_key?("records"))
                        record.merge!(parse_child(k, v))
                    end
                end
                record.merge!(reference_record)
                records << record
            end
            records
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
                next if Exclude_key_names.include?(k.to_s.downcase) || (k.to_s.downcase == "id" && v.nil?)
                result.merge!({k => v})
            end
            result
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