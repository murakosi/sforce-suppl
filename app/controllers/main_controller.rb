class MainController < ApplicationController
  before_action :require_sign_in!
  
  def index
  end
end
