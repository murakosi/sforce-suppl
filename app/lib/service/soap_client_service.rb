#require "soapforce"
require 'logger'

module Service
    class SoapClientService
        include Service::ServiceCore
    
        def call(params)
            #client = Soapforce::Client.new(client_options(params))
            client = Client.new(client_options(params))
        end

        private
            def client_options(params)

                {
                    :wsdl => Service::ResourceLocator.call(:partner_wsdl),
                    :version => params[:api_version] || Constants::DefaultApiVersion,
                    :host => Utils::SforceApiUtils.sforce_host(params),
                    :ssl_version => Constants::SSLVersion,
                    :ssl_ca_cert_file => Utils::SforceApiUtils.ssl_certificate,
                    :proxy => proxy,
                    :tag_style => params[:tag_style],
                    :logger => set_temp_logger,
                    :log => false
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

            def set_temp_logger
                file_name = File.expand_path("log/" + "soap_log.txt", Rails.root)
                if File.exist?(file_name)                  
                    File.open(file_name, 'w') do |file|
                        file.close
                    end

                end
                Logger.new(file_name)
            end
    end
end
