module DescribeHelper

    def initial_sobjects_list
        describe_result = current_client.describe_global()
        sobjects_list = describe_result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
        sobjects_list.select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    end
end