class MainController < ApplicationController
  include Describe::DescribeExecuter

  before_action :require_sign_in!

  protect_from_forgery except: [:check]

  def index
    @deploy_metadata_options = Metadata::Deployer.deploy_options
    @default_debug_levels = Constants::DefaultLogLevel
    @debug_options = Constants::LogCategory.map{|cat| {cat => Constants::LogCategoryLevel} }
    @describe_error = nil
    @describe_result = nil

    begin
      describe_global(sforce_session)
      sobjects = session[:global_result].map{|hash| hash[:name]}
      html_content = render_to_string :partial => 'sobjectlist', :locals => {:data_source => sobjects}
      @describe_result = html_content
    rescue StandardError => ex      
      @describe_error = ex.message
    end
  end

  def check
  	render :plain => "ok", :status => 200
  end

  def describe_global(sforce_session)
    begin
      result = Service::SoapSessionService.call(sforce_session).describe_global()
      session[:global_result] = result[:sobjects].map { |sobject| {:name => sobject[:name], :is_custom => sobject[:custom]} }
    rescue StandardError => ex
      session[:global_result] = nil
    end
  end

end
