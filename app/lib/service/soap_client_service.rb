require "soapforce"

module Service
    class SoapClientService
        include Service::ServiceCore
    
        def call(params)
            client = Soapforce::Client.new(client_options(params))
        end

        private
            def client_options(params)
                {
                    :wsdl => Service::ResourceLocator.call(:partner_wsdl),
                    :version => params[:api_version],
                    :host => Utils::SforceApiUtils.sforce_host(params),
                    :ssl_version => Constants::SSLVersion,
                    :ssl_ca_cert_file => Utils::SforceApiUtils.ssl_certificate
                    #:logger => Logger.new(STDOUT)
                }                
            end
    end
end