module Soql
    module QueryExecuter
        
        Exclude_key_names = ["@xsi:type", "type"]
        
        def execute_query(sforce_session, soql)
            query_result = Service::SoapSessionService.call(sforce_session).query(soql)

            if query_result.empty?
               raise StandardError.new("No matched records found")
            end
            
            format_query_result(query_result)
        end

        def format_query_result(result)
#=begin
            @ret = {}
            result.records.each{|item| parse(item)}
            p "result"
            p @ret
            @ret
#=end
=begin
            result.records.map{ |record| record.to_h }
                            .map{ |hash| hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                }
=end
        end
        
        def parse(records)
            if records.is_a?(Soapforce::SObject)
                records = records.raw_hash
            end
            records.each do |k,v|
                p v.class
                if v.is_a?(Hash)
                    p "hash"
                    p v
                    parse(v)
                else
                    simple = simplize(k,v)
                    p "simple"
                    p simple
                    @ret.merge!(simple) unless simple.nil?
                end
            end
        end
        
        def simplize(k,v)
            if Exclude_key_names.include?(k.to_s)
                nil
            elsif k.to_s == "id" && v.nil?
                nil
            else
               {k => v}
            end
        end
    end
end