module DescribeHelper

    def self.describe_global(client)
        result = client.describe_global()
        @global_result = result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
    end

    def self.is_global_fetched?
        @global_result.present?
    end

    def self.global_result
        @global_result
    end

    def self.describe_object(client, object_name)
        result = client.describe(object_name)
        @object_result = result
    end

    def self.object_result
        @object_result
    end
end
