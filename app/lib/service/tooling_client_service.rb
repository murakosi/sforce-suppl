require 'logger'

module Service
    class ToolingClientService
        include Service::ServiceCore
    
        def call(params)
            client = Tooling::Client.new(client_options(params))
            client.authenticate(soap_session(params))
            client
        end

        private
            def client_options(params)               
                {
                    :wsdl => Service::ResourceLocator.call(:tooling_wsdl),
                    :ssl_version => Constants::SSLVersion,
                    :ssl_ca_cert_file => Utils::SforceApiUtils.ssl_certificate,
                    :logger => set_temp_logger,
                    :log => true
                }                
            end

            def set_temp_logger
                file_name = File.expand_path("log/" + "tooling_log.txt", Rails.root)
                if File.exist?(file_name)                  
                    File.open(file_name, 'w') do |file|
                        file.close
                    end

                end
                Logger.new(file_name)
            end

            def soap_session(params)
                {:session_id => params[:session_id], :server_url => params[:server_url]}
            end
    end
end