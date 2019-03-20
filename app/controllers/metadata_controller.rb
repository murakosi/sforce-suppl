
class MetadataController < ApplicationController
    include Metadata::Formatter
    include Metadata::Crud
    include Metadata::SessionController
    include Generator::GridDataGenerator

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :read, :prepare, :edit, :crud, :retrieve, :check_retrieve_status, :retrieve_result, :deploy, :check_deploy_status]

    Full_name_index = 4
    
    #----------------------------------
    # Responses select options of metadata types
    #----------------------------------
    def show
        begin
            metadata_types = get_metadata_types(sforce_session)
            html_content = render_to_string :partial => 'metadatalist', :locals => {:data_source => metadata_types}
            render :json => {:target => "#metadata_list", :content => html_content, :error => nil, :status => 200}
        rescue StandardError => ex
            html_content = render_to_string :partial => 'metadatalist', :locals => {:data_source => []}
            render :json => {:target => "#metadata_list", :content => html_content, :error => ex.message, :status => 400}
        end        
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
        metadata_list = list_metadata(sforce_session, metadata_type)

        if metadata_list.nil?
            raise StandardError.new("No metadata available")
        else
            formatted_list = format_metadata_list(metadata_list)
        end

        field_types = get_field_value_types(sforce_session, metadata_type)
        formatted_field_types = format_field_type_result(sforce_session, metadata_type, field_types)
        crud_info = api_crud_info(field_types)
        parent_tree_nodes = format_parent_tree_nodes(crud_info, formatted_list)            
        clear_session(metadata_type, formatted_field_types)

        list_response_json(metadata_type, formatted_list, parent_tree_nodes, formatted_field_types, crud_info)
    end

    def list_response_json(metadata_type, formatted_list, parent_tree_nodes, field_types, crud_info)
        {
            :fullName => metadata_type,
            :list_grid => list_grid_column_options(formatted_list),
            :tree => parent_tree_nodes,
            :create_grid => create_grid_options(metadata_type, crud_info, field_types),
            :crud_info => crud_info
        }
    end

    def read
        metadata_type = params[:metadata_type]
        full_name = params[:name]

        begin
            raise_when_type_unmached(metadata_type)
            result = read_metadata(sforce_session, metadata_type, full_name)
            tree_data = format_read_result(full_name, result, current_metadata_field_types)
            try_save_session(metadata_type, full_name, result)
            render :json => {:tree => tree_data}, :status => 200            
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

    def crud
        crud_type = params[:crud_type]
        metadata_type = params[:metadata_type]

        begin
            raise_when_type_unmached(metadata_type)
            result = change_metadata(crud_type, metadata_type)
            render :json => {:message => result[:message], :refresh_required => result[:refresh_required]}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def change_metadata(crud_type, metadata_type)
        case crud_type
        when Metadata::CrudType::Create
            try_create(metadata_type)
        when Metadata::CrudType::Update
            try_update(metadata_type)
        when Metadata::CrudType::Delete
            try_delete(metadata_type)
        else
            raise StandardError.new("Invalid crud type")
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

    def try_create(metadata_type)
        field_headers = params[:field_headers]
        field_types = params[:field_types]
        field_values = JSON.parse(params[:field_values])
        create_metadata(sforce_session, metadata_type, field_headers, field_types, field_values)
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
              :disposition => 'attachment',
              :type => 'application/x-compress',
              :filename => result[:metadta_type] + '.zip',
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