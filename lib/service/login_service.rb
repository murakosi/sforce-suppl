module Sforcesuppl
    module Service
        module SforceClients
            def soap_client
                client = Soapforce::Client.new
                client.authenticate(soap_session)
                client
            end

            def metadata_client
                client = Sforcesuppl::Client.new
                client.authenticate(metadata_session)
                client   
            end

            def current_user
                login_token = User.encrypt(session[:user_token])
                current_user ||= User.find_by(user_token: login_token)
            end

            def soap_session
                {:session_id => @current_user.sforce_session_id, :server_url => @current_user.sforce_server_url}
            end

            def metadata_session
                {:session_id => @current_user.sforce_session_id, :metadata_server_url => @current_user.sforce_metadata_server_url}
            end
        end
    end
end