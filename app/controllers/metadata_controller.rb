require "cgi"

class MetadataController < ApplicationController
    include Metadata::Builder
    include Metadata::Crud
    include Metadata::SessionController

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :edit, :crud, :retrieve, :check_retrieve_status, :retrieve_result, :deploy, :check_deploy_status]

    Full_name_index = 4
    
    def show   
    end

    def list
        metadata_type = params[:selected_directory]

        begin
            response = execute_list_metadata(metadata_type)
            render :json => response, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def execute_list_metadata(metadata_type)
        metadata_list = Service::MetadataClientService.call(sforce_session).list(metadata_type)

        if metadata_list.nil?
            raise StandardError.new("No metadata available")
        else
            formatted_list = build_metadata_list(metadata_list)
        end

        field_types = Service::MetadataClientService.call(sforce_session).describe_value_type(metadata_type)
        formatted_field_types = build_field_type_result(metadata_type, field_types)
        crud_info = build_crud_info(field_types)
        parent_tree_nodes = build_parent_nodes(crud_info, formatted_list)
        clear_session(metadata_type, formatted_field_types)

        get_list_response(metadata_type, formatted_list, parent_tree_nodes, crud_info)
    end

    def get_list_response(metadata_type, metadata_list, parent_tree_nodes, crud_info)
        {
            :fullName => metadata_type,
            :metadata_list =>   {
                                    :rows => metadata_list.map{|hash| [false] + hash.values},
                                    :column_options => get_column_options(metadata_list),
                                    :columns => [""] + metadata_list.first.keys
                                },
            :tree => parent_tree_nodes,
            :crud_info => crud_info
        }
    end

    def get_column_options(metadata_list)
        column_options = [{:type => "checkbox", :readOnly => false, :className => "htCenter htMiddle"}]
        metadata_list.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        column_options
    end

    def crud
        crud_type = params[:crud_type]
        metadata_type = params[:metadata_type]

        case crud_type
        when Metadata::CrudType::Read
            try_read(metadata_type)
        when Metadata::CrudType::Update
            change_metadata(crud_type, metadata_type)
        when Metadata::CrudType::Delete
            change_metadata(crud_type, metadata_type)
        else
            render :json => {:error => "Invalid crud type"}, :status => 400
        end 
    end

    def try_read(metadata_type)
        full_name = params[:name]

        begin
            raise_when_type_unmached(metadata_type)
            result = read_metadata(sforce_session, metadata_type, full_name)
            tree_data = build_read_result(full_name, result, current_metadata_field_types)
            try_save_session(metadata_type, full_name, result)
            render :json => {:tree => tree_data}, :status => 200            
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def change_metadata(crud_type, metadata_type)
        begin
            raise_when_type_unmached(metadata_type)
            case crud_type
            when Metadata::CrudType::Update
                result = try_update(metadata_type)
            when Metadata::CrudType::Delete
                result = try_delete(metadata_type)
            end                 
            render :json => {:message => result[:message], :refresh_required => result[:refresh_required]}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def edit
        metadata_type = params[:metadata_type]
        node_id = params[:node_id]
        full_name = params[:full_name]
        path = params[:path]
        new_text = params[:new_value]
        old_text = params[:old_value]
        data_type = params[:data_type]
        
        begin
            raise_when_type_unmached(metadata_type)
            edit_result = edit_metadata(read_results[full_name], path, new_text, data_type)
            try_save_session(metadata_type, full_name, edit_result)
            render :json => {:full_name => full_name}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:node_id => node_id, :old_text => old_text, :error => ex.message}, :status => 400
        end
    end

    def try_update(metadata_type)
        full_names = params[:full_names]
        if full_names.nil?
            raise StandardError.new("No node is selected")
        end

        update_metadata(sforce_session, metadata_type, read_results, full_names)
    end

    def try_delete(metadata_type)
        selected_records = JSON.parse(params[:selected_records])
        full_names = extract_full_names(selected_records)
        delete_metadata(sforce_session, metadata_type, full_names)      
    end

    def retrieve
        metadata_type = params[:selected_type]
        selected_records = JSON.parse(params[:selected_records])
        
        begin
            full_names = extract_full_names(selected_records)
            raise_when_type_unmached(metadata_type)
            async_result = Metadata::Retriever.retrieve(sforce_session, metadata_type, full_names)
            render :json => {:id => async_result[:id], :done => async_result[:done]}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end
    
    def check_retrieve_status
        status = Metadata::Retriever.retrieve_status
        render :json => {:id => status[:id], :done => status[:done]}, :status => 200
    end
    
    def retrieve_result
        begin
            result = Metadata::Retriever.retrieve_result
            send_data(result[:zip_file],
              :disposition => "attachment",
              :type => "application/x-compress",
              :filename => result[:metadta_type] + ".zip",
              :status => 200
            )        
            set_download_success_cookie(response)
        rescue StandardError => ex
            print_error(ex)
            respond_download_error(ex.message)
        end
    end

    def deploy
        zip_file = params[:zip_file]
        options = JSON.parse(params[:options])

        begin
            async_result = Metadata::Deployer.deploy(sforce_session, zip_file, options)
            render :json => {:id => async_result[:id], :done => async_result[:done]}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def check_deploy_status
        begin
            deploy_result = Metadata::Deployer.check_deploy_status(true)
            render :json => {:id => deploy_result[:id], :done => deploy_result[:done], :result => deploy_result[:result], :details => deploy_result[:details]}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def extract_full_names(selected_records)
        if selected_records.empty?
            raise StandardError.new("No metadata selected")
        end
        selected_records.map{|array| array[Full_name_index]}
    end

end