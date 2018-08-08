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
            @ret = {}
            parse(result.records)
            @ret

=begin
            result.records.map{ |record| record.to_h }
                            .map{ |hash| hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                }
=end
        end
        
        def parse(records)
            records.each do | record|
                simple = simplize(record)
                p simple
                #if simple.is_a?(Hash)#simple.values.any?{|a| a.is_a?(Hash)}
                #    parse(simple.values)
                #else
                #    @ret.store(simple
                #end
            end
        end
        
        def simplize(h)
                hash = h.to_h
                simple = hash.map{ |hash| hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                }
        end
    end
end