class ApplicationController < ActionController::Base
  before_action :current_user
  before_action :require_sign_in!
  helper_method :signed_in?
  
  protect_from_forgery with: :exception

  def current_user
    login_token = User.encrypt(cookies[:user_login_token])
    @current_user ||= User.find_by(login_token: login_token)
  end

  def sign_in(user, result)
    login_token = User.new_login_token
    cookies.permanent[:user_login_token] = login_token
    user.update!(login_token: User.encrypt(login_token))
    @current_user = user
  end

  def sign_out
    @current_user = nil
    SforceClient.logout
    SforceClient.finalize
    cookies.delete(:user_login_token)
  end

  def signed_in?
    @current_user.present?
  end

  private

    def require_sign_in!
      redirect_to login_path unless signed_in?
    end

end
