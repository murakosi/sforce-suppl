module Service
    class SoapLoginService
        include Service::ServiceCore

        def call(params)
            client = Service::SoapClientService.call(params)
            client.authenticate(:username => params[:name], :password => params[:password])
        end
    end
end