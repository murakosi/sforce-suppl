module Service
    class SoapLoginService
    include Service::ServiceCore
    
        Production_url = "login.salesforce.com"
        Sandbox_url = "atest.salesforce.com"

        #def initialize(params)
        #    @params = params
        #end

        def call(params)
            if is_sandbox?(params)
                host = Sandbox_url
            else
                host = Production_url
            end

            client = Soapforce::Client.new(:host => host)
            client.authenticate(:username => params[:name], :password => params[:password])
        end

        private
            def is_sandbox?(params)
                ActiveRecord::Type::Boolean.new.cast(params[:is_sandbox])
            end
    end
end