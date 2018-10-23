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
                    :version => params[:api_version] || Constants::DefaultApiVersion,
                    :host => Utils::SforceApiUtils.sforce_host(params),
                    :ssl_version => Constants::SSLVersion,
                    :ssl_ca_cert_file => Utils::SforceApiUtils.ssl_certificate,
                    :proxy => proxy
                    #:logger => Logger.new(STDOUT)
                }                
            end

            def proxy
                if ENV["http_proxy"]
                    ENV["http_proxy"]
                elsif ENV["https_proxy"]
                    ENV["https_proxy"]
                else
                    nil
                end
            end
    end
end