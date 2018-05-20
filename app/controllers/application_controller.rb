#require "metadata"
#require "describe"

class ApplicationController < ActionController::Base
  before_action :current_user
  before_action :require_sign_in!
  helper_method :signed_in?, :current_user, :sforce_session

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
      redirect_to login_path unless signed_in?
  end

  private
  
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
      return false
    end
  end
end
