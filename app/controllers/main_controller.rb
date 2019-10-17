    class MainController < ApplicationController
    include Describe::DescribeExecuter

    before_action :require_sign_in!

    protect_from_forgery except: [:check, :refresh_sobjects, :refresh_metadata]

    def index
        @deploy_metadata_options = Metadata::Deployer.default_deploy_options
        @default_debug_levels = Constants::DefaultLogLevel
        @debug_options = Constants::LogCategory.map{|cat| {cat => Constants::LogCategoryLevel} }
        @describe_global_error = nil
        @sobject_list = nil
        @describe_metadata_objects_error = nil
        @metadata_list = nil

        preprare_sobjects()
        prepare_metadata_types()
    end

    def check
    	render :plain => "ok", :status => 200
    end

    def refresh_sobjects
        session[:global_result] = nil
        begin
            sobjects = get_sobject_names(sforce_session, Describe::SobjectType::All)
            html_content = render_to_string :partial => 'sobjectlist', :locals => {:data_source => sobjects}
            render :json => {:result => html_content}, :status => 200
        rescue StandardError => ex
            print_error(ex)            
            render :json => {:error => ex.message}, :status => 400
        end            
    end

    def refresh_metadata
        current_user.metadata_types = []
        begin
            metadata_types = describe_metadata_objects()
            html_content = render_to_string :partial => "metadatalist", :locals => {:data_source => metadata_types}
            render :json => {:result => html_content}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def preprare_sobjects
        begin
            sobjects = get_sobject_names(sforce_session, Describe::SobjectType::All)
            html_content = render_to_string :partial => 'sobjectlist', :locals => {:data_source => sobjects}
            @sobject_list = html_content
        rescue StandardError => ex
            print_error(ex)
            session[:global_result] = nil
            @describe_global_error = ex.message
        end    
    end

    def prepare_metadata_types
        begin
            metadata_types = describe_metadata_objects()
            html_content = render_to_string :partial => "metadatalist", :locals => {:data_source => metadata_types}
            @metadata_list = html_content
        rescue StandardError => ex
            print_error(ex)
            @describe_metadata_objects_error = ex.message
        end
    end

    def describe_metadata_objects
        if current_user.metadata_types.empty?
            metadata_types = Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
            Service::UpdateUserService.call(current_user, {:type => :metadata_types, :metadata_types => metadata_types})
        end

        current_user.metadata_types
    end
end
