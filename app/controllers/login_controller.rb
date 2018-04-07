class LoginController < ApplicationController
  before_action :require_sign_in!, except: [:destroy]
  skip_before_action :require_sign_in!, only: [:new, :create]

  def new
  end

  def create
    @error_message = ""

    begin
      #sforcelogin_to_salesforce(login_params)
      sign_in(login_params)
      redirect_to soqlexecuter_path
    rescue Savon::SOAPFault => e
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

    #def register_user
    #  set_user()
    #  sign_in(@user)
    #  redirect_to soqlexecuter_path
    #end

    #def set_user
    #  begin
    #    @user = User.find_by!(name: login_params[:name])
    #  rescue ActiveRecord::RecordNotFound => ex
    #    @user = User.create(login_params)
    #  end
    #end

    def login_params
      params.require(:login_param).permit(:name, :password, :is_sandbox)
    end
end