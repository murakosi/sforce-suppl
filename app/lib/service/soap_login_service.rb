module Service
    class SoapLoginService
        include Service::ServiceCore
    
        Production_url = "login.salesforce.com"
        Sandbox_url = "test.salesforce.com"

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