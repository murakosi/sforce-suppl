class LoginController < ApplicationController
  before_action :require_sign_in!, except: [:destroy]
  skip_before_action :require_sign_in!, only: [:new, :create]
  protect_from_forgery :except => [:create]

  def new
  end

  def create
    begin
      sign_in(login_params)
      redirect_to main_path
    rescue StandardError => ex
      flash[:danger] = safe_encode(ex.message)
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