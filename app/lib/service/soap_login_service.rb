module Service
    class SoapLoginService
        include Service::ServiceCore

        def call(params)
            client = Service::SoapClientService.call(params)
            a = client.authenticate(:username => params[:name], :password => params[:password])
            p a
            a
        end
    end
end