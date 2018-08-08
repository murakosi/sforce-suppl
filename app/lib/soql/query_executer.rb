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
            parse(result.records)
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
            records.each do | record|
                #simple = simplize(record)
                if record.has_key?(:records)
                    parse(record[:records])
                else
                    @ret.merge!(record)
                end
            end
        end
        
        def simplize(h)
                p "this"
                p h
                if h.is_a?(Hash)
                    hash = h
                else
                    hash = h.raw_hash
                end
                nh = {}
               hash.each do |k,v|
                    next if Exclude_key_names.include?(k.to_s) || (k.to_s == "id" && v.nil?)
                    nh.merge!({k=>v})
               end
               p nh
               nh
        end
    end
end