module Service
    class MetadataClientService
        include Service::ServiceCore
    
        def call(params)
            client = Metadata::Client.new(client_options(params))
            client.authenticate(metadata_session(params))
            client
        end

        private
            def client_options(params)
                {
                    :wsdl => Service::ResourceLocator.call(:metadata_wsdl),
                    :version => params[:api_version],
                    :ssl_version => Constants::SSLVersion,
                    :ssl_ca_cert_file => Utils::SforceApiUtils.ssl_certificate
                    #:logger => Logger.new(STDOUT)
                }                
            end

            def metadata_session(params)
                {:session_id => params[:session_id], :metadata_server_url => params[:metadata_server_url]}
            end
    end
end