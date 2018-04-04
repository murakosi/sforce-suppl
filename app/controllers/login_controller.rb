class LoginController < ApplicationController
  before_action :require_sign_in!, except: [:destroy]
  skip_before_action :require_sign_in!, only: [:new, :create]

  def new
  end

  def create
    @error_message = ""

    begin
      login_to_salesforce(login_params)
      register_user()
    rescue StandardError=> e
      @error_message = e.message
      render 'new'
    end
  end

  def destroy
    sign_out()
    redirect_to login_path
  end

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
        @user = User.find_by!(name: login_params[:name])
      rescue ActiveRecord::RecordNotFound => ex
        @user = User.create(session_params)
      end
    end

    # 許可するパラメータ
    def login_params
      params.require(:login_param).permit(:name, :password, :is_sandbox)
    end
end
