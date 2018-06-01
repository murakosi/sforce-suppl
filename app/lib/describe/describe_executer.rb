module Describe
    module DescribeExecuter

        def get_sobject_names(sforce_session, sobject_type)
            raw_result = describe_global(sforce_session)
            map_global_result(raw_result, sobject_type)
        end

        def describe_global(sforce_session)
            if session[:global_result]
                session[:global_result]
            else
                result = Service::SoapClientService.call(sforce_session).describe_global()
                session[:global_result] = result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
            end
        end

        def describe_field(sforce_session, object_name)
            Service::SoapClientService.call(sforce_session).describe(object_name)
        end

        def field_result(object_name)
            Describe::DescribeResults.field_result[object_name]
        end

        def format_field_result(object_name, field_result)
            Describe::DescribeFormatter.format(field_result)
        end

        def formatted_field_result(object_name)
            Describe::DescribeResults.formatted_field_result[object_name]
        end

        private

            def map_global_result(raw_result, sobject_type)
                if sobject_type == Describe::SobjectType::All
                    all_sobject_names(raw_result)
                elsif sobject_type == Describe::SobjectType::Standard
                    standard_sobject_names(raw_result)
                elsif sobject_type == Describe::SobjectType::Custom
                    custom_sobject_names(raw_result)
                end
            end

            def all_sobject_names(raw_result)
                raw_result.map{|hash| hash[:name]}
            end

            def standard_sobject_names(raw_result)
                raw_result.reject{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
            end

            def custom_sobject_names(raw_result)
                raw_result.select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
            end
    end
end