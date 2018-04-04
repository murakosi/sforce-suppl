class ApplicationController < ActionController::Base
  before_action :current_user
  before_action :require_sign_in!
  helper_method :signed_in?
  
  protect_from_forgery with: :exception
  
  def login_to_salesforce(login_params)
    client = Soapforce::Client.new
    result = client.authenticate(username: login_params[:name], password: login_params[:password])
    save_sforce_session(result)
  end

  def sign_in(user)
    login_token = User.new_login_token
    session[:user_login_token] = login_token
    user.update!(login_token: User.encrypt(login_token))
    @current_user = user
  end

  def sign_out
    session.delete(:sforce_session)
    @current_user = nil
    session.delete(:user_login_token)
  end

  def signed_in?
    @current_user.present?
  end

  def current_client
    #begin
    sforce_session = session[:sforce_session].symbolize_keys
    client = Soapforce::Client.new
    begin
      client.authenticate(sforce_session)
      return client
    rescue Savon::SOAPFault => e
      fault_code = e.to_hash[:fault][:faultcode]
      if fault_code == "sf:INVALID_SESSION_ID"
        return client
      else
        raise e
      end
    end
  end

  private
    def current_user
      login_token = User.encrypt(session[:user_login_token])
      @current_user ||= User.find_by(login_token: login_token)
    end

    def require_sign_in!
      redirect_to login_path unless signed_in?
    end

    def save_sforce_session(result)
      session_info = {:session_id => result[:session_id], :server_url => result[:server_url]}
      session[:sforce_session] = session_info
    end
end
