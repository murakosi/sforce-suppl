class ApplicationController < ActionController::Base
  before_action :current_user
  before_action :require_sign_in!
  helper_method :signed_in?, :current_client, :metadata_client

  protect_from_forgery with: :exception

  Production_url = "login.salesforce.com"
  Sandbox_url = "test.salesforce.com"

  def login_to_salesforce(login_params)
    if is_sandbox?(login_params)
      host = Sandbox_url
    else
      host = Production_url
    end

    client = Soapforce::Client.new
    client.authenticate(:username => login_params[:name], :password => login_params[:password], :host => host)
  end

  def sign_in(login_params)
    sforce_result = login_to_salesforce(login_params)
    
    user = get_user(login_params)
    login_token = User.new_login_token
    session[:user_token] = login_token

    user.update_attributes(get_attributes(login_token, sforce_result))
    
    @current_user = user
  end

  def sign_out
    current_client.logout()
    @current_user = nil
    session.delete(:user_token)
  end

  def signed_in?
    @current_user.present? && valid_sforce_session?
  end

  def valid_sforce_session?
    begin
      current_client()
      return true
    rescue StandardError => ex
      return false
    end
  end

  def current_client
    client = Soapforce::Client.new
    client.authenticate(sforce_session)
    client
  end

  def metadata_client
    client = Metadata::Client.new
    client.authenticate(sforce_metadata_session)
    client   
  end

  private
  
    def current_user
      login_token = User.encrypt(session[:user_token])
      @current_user ||= User.find_by(user_token: login_token)
    end

    def get_user(login_params)
      begin
        User.find_by!(name: login_params[:name])
      rescue ActiveRecord::RecordNotFound => ex
        User.create(login_params)
      end
    end

    def require_sign_in!
      redirect_to login_path unless signed_in?
    end

    def get_attributes(token, result)
      {
        :user_token => User.encrypt(token),
        :sforce_session_id => result[:session_id],
        :sforce_server_url => result[:server_url], 
        :sforce_query_locator => result[:query_locator],
        :sforce_metadata_server_url => result[:metadata_server_url]
      }
    end

    def sforce_session
      {:session_id => @current_user.sforce_session_id, :server_url => @current_user.sforce_server_url}
    end

    def sforce_metadata_session
      {:session_id => @current_user.sforce_session_id, :metadata_server_url => @current_user.sforce_metadata_server_url}
    end

    def is_sandbox?(login_params)
      ActiveRecord::Type::Boolean.new.cast(login_params[:is_sandbox])
    end

end
