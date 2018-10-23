class LoginController < ApplicationController
    before_action :require_sign_in!, except: [:destroy]
    skip_before_action :require_sign_in!, only: [:new, :create]
    protect_from_forgery :except => [:create]

    helper_method :api_version_list

    def new
    end

    def create
        begin
          flash[:danger] = nil
          sign_in(login_params)
          redirect_to main_path
        rescue StandardError => ex
          print_error(ex)
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
          params.require(:login_param).permit(:name, :password, :sandbox, :api_version)
        end

        def api_version_list
          Constants::ApiVersions
        end
end