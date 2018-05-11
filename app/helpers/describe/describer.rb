module Describe
    class Describer
        class << self
           
        def describe_global(client)
            if DescribeResults.global_result.present?
                DescribeResults.global_result
            else
                result = client.describe_global()
                DescribeResults.global_result = result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
            end
        end

        def describe_field(client, object_name)
            DescribeResults.field_result = client.describe(object_name)
            DescribeResults.object_name = object_name
            DescribeResults.field_result
        end

        def describe_field_result
            DescribeResults.field_result
        end
        
        def described_object_name
            DescribeResults.object_name
        end

        def format_field_result(field_result)
            DescribeResults.formatted_field_result = Describe::DescribeFormatter.format_field_result(field_result)
        end

        def formatted_field_result
            DescribeResults.formatted_field_result
        end

        def get_sobject_info(field_result)
            info = "表示ラベル：" + field_result[:label] + "\n" +
                "API参照名：" + field_result[:name] + "\n" +
                "プレフィックス：" + field_result[:key_prefix]
        end

        private
        class DescribeResults
            class << self
                attr_accessor :object_name
                attr_accessor :global_result
                attr_accessor :field_result
                attr_accessor :formatted_field_result
            end
        end
    end
    end
end