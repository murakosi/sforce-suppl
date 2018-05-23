class LoginController < ApplicationController
  before_action :require_sign_in!, except: [:destroy]
  skip_before_action :require_sign_in!, only: [:new, :create]

  def new
  end

  def create
    @error_message = ""

    begin
      sign_in(login_params)
      redirect_to main_path
    rescue StandardError => e
      #@error_message = e.message
      flash[:danger] = e.message
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