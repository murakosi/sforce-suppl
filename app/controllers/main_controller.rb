class MainController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery except: [:switch, :check]

  def index
    @deploy_metadata_options = Metadata::Deployer.deploy_options
    @default_debug_levels = Constants::DefaultLogLevel
    @debug_options = Constants::LogCategory.map{|cat| {cat => Constants::LogCategoryLevel} }
  end

  def switch
    #render :plain => "metadata", :status => 200
    #render :plain => "describe", :status => 200
    render :plain => current_user.name, :status => 200
  end

  def check
  	render :plain => "ok", :status => 200
  end
end
