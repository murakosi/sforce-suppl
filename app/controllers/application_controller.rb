#require "metadata"
#require "describe"

class ApplicationController < ActionController::Base
    include AjaxRedirectHelper

    before_action :current_user
    before_action :require_sign_in!
    helper_method :signed_in?, :current_user, :sforce_session

    Redirect_message = "<b>Redirected due to session/connection error</b>.\n\n"

    protect_from_forgery with: :exception

    def sign_in(login_params)
        sforce_result = Service::SoapLoginService.call(login_params)
        login_token = Service::UpdateUserService.call(login_params, sforce_result)
        session[:user_token] = login_token
    end

    def sign_out
        Service::SoapLogoutService.call(@sforce_session)
        @current_user = nil
        session.delete(:user_token)
    end

    def signed_in?
        @current_user.present? && sforce_session_alive?
    end

    def require_sign_in!
        force_redirect unless signed_in?
    end

    private
        def current_user
                        p request.format
            user_info = Service::SelectUserService.call(session[:user_token])
            @sforce_session = user_info[:sforce_session]
            @current_user = user_info[:user]
        end
        
        def sforce_session
            @sforce_session
        end

        def sforce_session_alive?
            #return false
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
                message = Redirect_message + @sforce_session_error.encode("UTF-8", invalid: :replace, undef: :replace)
                flash[:danger] = message
            end            
        end
end
