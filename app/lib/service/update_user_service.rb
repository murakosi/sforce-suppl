module Service
    class UpdateUserService
        include Service::ServiceCore
    
        def call(login_params, sforce_result)
            user = set_user(login_params)
            login_token = User.new_login_token
            user.update_attributes(get_attributes(login_token, login_params, sforce_result))
            login_token
        end

        def set_user(login_params)
            begin
                User.find_by!(name: login_params[:name])
            rescue ActiveRecord::RecordNotFound => ex
                User.create(login_params)
            end
        end

        def get_attributes(login_token, login_params, sforce_result)
            {
                :user_token => User.encrypt_token(login_token),
                :sforce_session_id => sforce_result[:session_id],
                :sforce_server_url => sforce_result[:server_url], 
                :sforce_query_locator => sforce_result[:query_locator],
                :sforce_metadata_server_url => sforce_result[:metadata_server_url],
                :sandbox => login_params[:sandbox],
                :api_version => login_params[:api_version]
            }
        end        
    end
end