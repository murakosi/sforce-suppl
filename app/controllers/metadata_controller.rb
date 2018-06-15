require 'json'

class MetadataController < ApplicationController
    include Metadata::Formatter
    include Metadata::Reader
    include Metadata::SessionController
    include Metadata::GridDataGenerator

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :read, :prepare, :edit, :crud, :download]
    
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
            metadata_list = list_metadata(sforce_session, metadata_type)
            if metadata_list.nil?
                raise StandardError.new("No metadata available")
            else
                formatted_list = format_metadata_list(metadata_list)
            end           
            parent_tree_nodes = format_parent_tree_nodes(formatted_list)
            field_types = get_field_value_types(sforce_session, metadata_type)
            clear_session(metadata_type)
            render :json => list_response_json(metadata_type, formatted_list, parent_tree_nodes, field_types), :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end   

    def list_response_json(metadata_type, formatted_list, parent_tree_nodes, field_types)
        {
            :fullName => metadata_type,
            :list_grid => list_grid_column_options(formatted_list),
            :tree => parent_tree_nodes,
            :create_grid => create_grid_options(field_types),
            :crud_info => api_crud_info(field_types)
        }
    end

    def read
        metadata_type = params[:metadata_type]
        full_name = params[:name]

        begin
            raise_when_type_unmached(metadata_type)
            result = read_metadata(sforce_session, metadata_type, full_name)
            tree_data = format(Metadata::FormatType::Edit, full_name, result)
            try_save_session(metadata_type, full_name, result)
            render :json => read_response_json(result, tree_data), :status => 200            
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def read_response_json(raw_hash, tree_data)
         {
            :raw => raw_hash,
            :tree => tree_data
        }
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
            edit_result = edit_metadata(session[:read_result][full_name], path, new_text, data_type)
            try_save_session(metadata_type, full_name, edit_result)
            render :json => {:result => "ok"}, :status => 200
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
            change_metadata(crud_type, metadata_type)
            render :json => {:message => crud_type.camelize + " complate"}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def change_metadata(crud_type, metadata_type)
        if crud_type == "update"
            try_update(metadata_type)
        elsif crud_type == "delete"
            try_delete(metadata_type)
        elsif crud_type == "create"
            try_create(metadata_type)
        else
            raise StandardError.new("Invalid crud type")
        end     
    end

    def try_update(metadata_type)
        update_metadata(sforce_session, metadata_type, read_results())
    end

    def try_delete(metadata_type)
        full_names = params[:full_names]
        delete_metadata(sforce_session, metadata_type, full_names)      
    end

    def try_create(metadata_type)
        data = params[:data]
        p data.values
    end

    def download
        metadata_type = params[:selected_type]
        full_names = params[:full_names]
        export_format = params[:dl_format]

        if full_names.nil?
            respond_download_error("No record selected")
            return
        end

        begin
            raise_when_type_unmached(metadata_type)
            try_download(export_format, metadata_type, full_names)
            set_download_success_cookie(response)
        rescue StandardError => ex
            print_error(ex)
            respond_download_error(ex.message)
        end
    end

    def try_download(format, metadata_type, full_names)
        if format == "csv"
            full_name = full_names.first
            result = read_metadata(sforce_session, metadata_type, full_name)
            download_csv(full_name, result)
        elsif format == "xml"
            download_metadata(metadata_type, full_names)
        end
    end

    def download_metadata(metadata_type, full_names)
        result = Metadata::Retriever.retrieve(sforce_session, metadata_type, full_names)
        send_data(result[:zip_file],
          :disposition => 'attachment',
          :type => 'application/x-compress',
          :filename => result[:id] + '.zip',
          :status => 200
        )        
    end

    def download_csv(full_name, result)
        generator = Generator::MetadataCsvGenerator.new(Encoding::SJIS, "\r\n", true)
        send_data(generator.generate(:full_name => full_name, :data => result),
          :disposition => 'attachment',
          :type => 'text/csv',
          :filename => full_name + '.csv',
          :status => 200
        )    
    end

end