class LoginController < ApplicationController
  before_action :require_sign_in!, except: [:destroy]
  skip_before_action :require_sign_in!, only: [:new, :create]
  protect_from_forgery :except => [:create]

  def new
  end

  def create
    @error_message = ""

    begin
      sign_in(login_params)
      redirect_to main_path
    rescue StandardError => ex
      message = ex.message.encode("UTF-8", invalid: :replace, undef: :replace)
      flash[:danger] = message
      render 'new'
    end
  end

  def destroy
    sign_out()
    redirect_to login_path
  end

  private
    def login_params
      params.require(:login_param).permit(:name, :password, :is_sandbox)
    end
end