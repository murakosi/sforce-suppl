class MainController < ApplicationController
  before_action :require_sign_in!
  protect_from_forgery except: :index
  def index
    #render :js => "changeDisplay('describe');"
    #respond_to do |format|
      #p format
      #format.js { render :js => "changeDisplay('describe');" }
    #end
  end

  def switch
    render :plain => "describe", :status => 200
  end
end
