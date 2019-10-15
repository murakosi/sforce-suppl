module Service
    class SoapSessionService
    	include Service::ServiceCore
    
        def call(params)
            client = Service::SoapClientService.call(params)
            client.authenticate(soap_session(params))
            client  
        end

        private
            def soap_session(params)
                {:session_id => params[:session_id], :server_url => params[:server_url], :language => params[:language]}
            end
    end
end