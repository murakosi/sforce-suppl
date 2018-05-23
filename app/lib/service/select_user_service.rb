module Service
    class SelectUserService
    include Service::ServiceCore
    
        def call(token)
            login_token = User.encrypt_token(token)
            user ||= User.find_by(user_token: login_token)
            if user.nil?
                nil_user_info
            else
                valid_user_info(user)
            end 

        end

        def nil_user_info
            {:user => nil,
             :sforce_session => {
                                 :session_id => nil,
                                 :server_url => nil,
                                 :metadata_server_url => nil
                                 }
            }  
        end

        def valid_user_info(user)          
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