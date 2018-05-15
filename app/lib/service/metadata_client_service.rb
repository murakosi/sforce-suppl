module Service
    class MetadataClientService
    include Service::ServiceCore
    
        def call(params)
            client = Metadata::Client.new
            client.authenticate(metadata_session(params))
            client
        end

        private
            def metadata_session(params)
                {:session_id => params[:session_id], :metadata_server_url => params[:metadata_server_url]}
            end
    end
end