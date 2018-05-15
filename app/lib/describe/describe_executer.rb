module Describe
    module DescribeExecuter

        def describe_global(sforce_session)
            if Describe::DescribeResults.global_result.present?
                Describe::DescribeResults.global_result
            else
                result = Service::SoapClientService.call(sforce_session).describe_global()
                Describe::DescribeResults.global_result = result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
            end
        end

        def describe_field(sforce_session, object_name)
            if Describe::DescribeResults.field_result[object_name].present?
                Describe::DescribeResults.field_result[object_name]
            else
                Describe::DescribeResults.field_result[object_name] = Service::SoapClientService.call(sforce_session).describe(object_name)
            end
        end

        def field_result(object_name)
            Describe::DescribeResults.field_result[object_name]
        end

        def format_field_result(object_name, field_result)
            if Describe::DescribeResults.formatted_field_result[object_name].present?
                Describe::DescribeResults.formatted_field_result[object_name]
            else
                Describe::DescribeResults.formatted_field_result[object_name] = Describe::DescribeFormatter.format_field_result(field_result)
            end
        end

        def formatted_field_result(object_name)
            Describe::DescribeResults.formatted_field_result[object_name]
        end

        def get_sobject_info(field_result)
            info = "表示ラベル：" + field_result[:label] + "\n" +
                "API参照名：" + field_result[:name] + "\n" +
                "プレフィックス：" + field_result[:key_prefix]
        end
    end
end