module Sforceutils
    class SessionManager
    class << self
        def initiate(login_params)
            @sforce_result = set_client(login_params)
            @login_token = set_user(login_params)
            #update_user(login_token, sforce_result)
            #update_user(login_token)
        end

        def terminate
            @client.logout()
            @user = nil
            session.delete(:user_token)
        end

        def sesson_alive?
            @user.present? && @client.sforce_session_alive?
        end

        def set_client(login_params)
            @client = Sforceutils::SforceClient.new(self)
            sforce_result = @client.login(login_params)
        end

        def set_user(login_params)
            begin
                @user = User.find_by!(name: login_params[:name])
            rescue ActiveRecord::RecordNotFound => ex
                @user = User.create(login_params)
            end

            User.new_login_token
        end

        def refresh()                        
            @user.update_attributes(get_attributes(@login_token, @sforce_result))
        end

        def get_attributes(login_token, sforce_result)
            {
                :user_token => User.encrypt(login_token),
                :sforce_session_id => result[:session_id],
                :sforce_server_url => result[:server_url], 
                :sforce_query_locator => result[:query_locator],
                :sforce_metadata_server_url => result[:metadata_server_url]
            }
        end

        def current_user
            if @user.present?
                @user
            else
                login_token = User.encrypt(session[:user_token])
                @user ||= User.find_by(user_token: login_token)
            end
        end

        def sforce_session
            {:session_id => @user.sforce_session_id, :server_url => @user.sforce_server_url}
        end

        def sforce_metadata_session
            {:session_id => @user.sforce_session_id, :metadata_server_url => @user.sforce_metadata_server_url}
        end
    end
    end
end