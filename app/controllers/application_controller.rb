#require "metadata"
#require "describe"

class ApplicationController < ActionController::Base
    include Common

    before_action :current_user
    before_action :require_sign_in!

    Redirect_message = "<b>Redirected due to session/connection error</b>.\n\n"

    protect_from_forgery with: :exception

    def sign_in(login_params)
        sforce_result = Service::SoapLoginService.call(login_params)
        login_token = Service::UpdateUserService.call(login_params, sforce_result)
        initialize_session(login_token)
    end

    def sign_out
        Service::SoapLogoutService.call(@sforce_session)
        @current_user = nil
        reset_session
    end

    def signed_in?
        @current_user.present? && sforce_session_alive?
    end

    def require_sign_in!
        force_redirect unless signed_in?
    end

    private
        def initialize_session(login_token)
            Session.sweep
            reset_session
            session[:user_token] = login_token
        end

        def current_user
            user_info = Service::SelectUserService.call(session[:user_token])
            @sforce_session = user_info[:sforce_session]
            @current_user = user_info[:user]
        end
        
        def sforce_session
            @sforce_session
        end

        def sforce_session_alive?
            begin
                Service::SoapClientService.call(@sforce_session)
                return true
            rescue StandardError => ex
                @sforce_session_error = ex.message
                return false
            end
        end

        def force_redirect        
            set_flash_message
            respond_to do |format|
                format.js { render ajax_redirect_to(login_path) }
                format.html { redirect_to login_path }
                format.text { redirect_to login_path }
            end
        end

        def set_flash_message()
            flash.discard(:danger)
            if @sforce_session_error.present?
                message = Redirect_message + safe_encode(@sforce_session_error)
                flash[:danger] = message
            end            
        end
end
