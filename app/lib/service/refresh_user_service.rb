module Service
    class RefreshUserService
        include Service::ServiceCore
    
        def call(login_params, sforce_result)
            user = get_user(login_params)
            login_token = User.new_login_token
            if user.language.nil?
                language = Constants::Default_language
            else
                language = user.language
            end                
            user.update_attributes(get_attributes(login_token, login_params, sforce_result, language))
            login_token
        end

        def get_user(login_params)
            begin
                User.find_by!(:name => login_params[:name], :sandbox => Utils::SforceApiUtils.is_sandbox?(login_params))
            rescue ActiveRecord::RecordNotFound => ex
                User.create(:name => login_params[:name], :sandbox => login_params[:sandbox])
            end
        end

        def get_attributes(login_token, login_params, sforce_result, language)
            {
                :user_token => User.encrypt_token(login_token),
                :sforce_session_id => sforce_result[:session_id],
                :sforce_server_url => sforce_result[:server_url], 
                :sforce_query_locator => sforce_result[:query_locator],
                :sforce_metadata_server_url => sforce_result[:metadata_server_url],
                :sandbox => login_params[:sandbox],
                :api_version => login_params[:api_version],
                :language => language
            }
        end        
    end
end