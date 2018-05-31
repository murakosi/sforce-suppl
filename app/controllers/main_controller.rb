class MainController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery except: [:switch, :check]

  def index
  end

  def switch
    render :plain => "metadata", :status => 200
    #render :plain => "describe", :status => 200
  end

  def check
  	render :plain => "ok", :status => 200
  end
end
