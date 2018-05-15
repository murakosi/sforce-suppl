module Service
	class SoapLogoutService
	include Service::ServiceCore
	
		def call(params)
			client = SoapClientService.call(params)
			client.logout()
		end
	end
end