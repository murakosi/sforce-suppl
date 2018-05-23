class MainController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery except: :switch

  def index
  end

  def switch
    render :plain => "metadata", :status => 200
  end
end
