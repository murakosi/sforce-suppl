require "json"

module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        
        def execute_query(sforce_session, soql)
            query_result = Service::SoapSessionService.call(sforce_session).query(soql)

            if query_result.empty?
               raise StandardError.new("No matched records found")
            end
            
            parse_query_result(query_result)
        end

=begin
        def format_query_result(result)

            result.records.map{ |record| record.to_h }
                            .map{ |hash| hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                }
        end
=end        
        def parse_query_result(query_result)
            results = get_results(query_result.raw_result)
            records = []
            results.each do |result|
                record = extract(result[:records])
                record.each do |k,v|
                    if v.is_a?(Hash) && (v.has_key?(:records) || v.has_key?("records"))
                        record.merge!(parse_child(k, v))
                    end
                end
                records << record
            end
            records
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