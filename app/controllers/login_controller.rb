class LoginController < ApplicationController

  before_action :require_sign_in!, except: [:destroy]
#  before_action :set_user, only: [:create]
  skip_before_action :require_sign_in!, only: [:new, :create]

  def new
  end

  def create
    @error_message = ""

    #begin
      login_to_salesforce(session_params)
      register_user()
    #rescue StandardError => e
    #  @error_message = e.message
    #  render 'new'
    #end
  end

  def destroy
    sign_out()
    redirect_to login_path
  end

  #def login_to_salesforce
  #  client = Soapforce::Client.new
  #  @result = client.authenticate(username: session_params[:name], password: session_params[:password])
  #end

  private

    def skip_login
      if signed_in?
        redirect_to soqlexecuter_path
      end
    end

    def register_user
      set_user()
      sign_in(@user)
      redirect_to soqlexecuter_path
    end

    def set_user
      begin
        @user = User.find_by!(name: session_params[:name])
      rescue ActiveRecord::RecordNotFound => ex
        @user = User.create(session_params)
      end
    end

    # 許可するパラメータ
    def session_params
      params.require(:session).permit(:name, :password, :is_sandbox)
    end
end
