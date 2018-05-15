module Service
	class SoapClientService
	include Service::ServiceCore
	
		def call(params)
            client = Soapforce::Client.new
            client.authenticate(saop_session(params))
            client  
		end

		private
	        def saop_session(params)
            	{:session_id => params[:session_id], :server_url => params[:server_url]}
        	end
	end
end