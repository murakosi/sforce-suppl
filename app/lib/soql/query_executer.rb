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
            parse(result.records.raw_hash)
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
            records.each do | k, v|
                #simple = simplize(record)
                if v.is_a?(Hash)
                    parse(v)
                else
                    simple = simplize(k,v)
                    @ret.merge!(simple) unless simple.nil?
                end
            end
        end
        
        def simplize(k,v)
        p k
        p v
        if Exclude_key_names.include?(k.to_s)
            nil
        elsif k.to_s == "id" && v.nil?
            nil
        else
           {k => v}
        end
=begin        
            h
                            .map{ |hash| hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                }
=end                                
        end
    end
end