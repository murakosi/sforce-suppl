require 'logger'

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
                    :ssl_version => Constants::SSLVersion,
                    :ssl_ca_cert_file => Utils::SforceApiUtils.ssl_certificate,
                    :logger => set_temp_logger,
                    :log => true
                }                
            end

            def set_temp_logger
                file_name = File.expand_path("log/" + "metadata_log.txt", Rails.root)
                if File.exist?(file_name)                  
                    File.open(file_name, 'w') do |file|
                        file.close
                    end

                end
                Logger.new(file_name)
            end

            def metadata_session(params)
                {:session_id => params[:session_id], :metadata_server_url => params[:metadata_server_url]}
            end
    end
end