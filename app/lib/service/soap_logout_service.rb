module Service
    class SoapLogoutService
    	include Service::ServiceCore
    
        def call(params)
            client = SoapSessionService.call(params)
            client.logout()
        end
    end
end