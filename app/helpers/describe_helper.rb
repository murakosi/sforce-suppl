module DescribeHelper

    def initial_sobjects_list
        #describe_result = Sforceutils::SessionManager.soap_client.describe_global()
        describe_result = Service::SoapClientService.call(sforce_session).describe_global()
        sobjects_list = describe_result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
        sobjects_list.select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    end
end