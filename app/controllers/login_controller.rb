class LoginController < ApplicationController

  before_action :require_sign_in!, except: [:destroy]
  before_action :set_user, only: [:create]
  skip_before_action :require_sign_in!, only: [:new, :create]

  def new
  end

  def create
    sign_in(@user)

    @error_message = ""
    
    begin
      login_to_salesforce()
      redirect_to soqlexecuter_path
    rescue StandardError => e
      @error_message = e.message
    end
  end

  def destroy
    sign_out()
    redirect_to login_path
  end

  def login_to_salesforce
    @client = Soapforce::Client.new
    @client.authenticate(username: @user.name, password: @user.password)
  end

  private

    def set_user
      begin
        @user = User.find_by!(name: session_params[:name])
      rescue ActiveRecord::RecordNotFound => ex
        @user = User.create(session_params)
      end
    end

    # 許可するパラメータ
    def session_params
      params.require(:session).permit(:name, :password)
    end
end
