module Service
    class SelectUserService
	include Service::ServiceCore
	
        def call(token)
            login_token = User.encrypt(token)
            user ||= User.find_by(user_token: login_token)
            {:user => user,
             :sforce_session => {
                                 :session_id => user.sforce_session_id,
                                 :server_url => user.sforce_server_url,
                                 :metadata_server_url => user.sforce_metadata_server_url
                                 }
            }
        end
    end
end