
class MetadataController < ApplicationController
    include Metadata::Formatter
    include Metadata::Reader

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :read, :prepare, :edit, :save, :download]
    
    Full_name_indxe = 3
    Max_metadata_count = 5
    
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
            end
            formatted_list = format_metadata_list(metadata_list)
            parent_tree_nodes = format_parent_tree_nodes(formatted_list)
            clear_session(metadata_type)
            render :json => list_response_json(metadata_type, formatted_list, parent_tree_nodes), :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end   

    def clear_session(metadata_type)
        session[:metadata_type] = metadata_type
        session[:read_result] = {}
    end

    def current_metadata_type
        session[:metadata_type]
    end

    def raise_error_when_type_unmached(metadata_type)
        if session[:metadata_type] != metadata_type
            raise StandardError.new("Metadata type has been changed")
        end
    end

    def try_save_session(metadata_type, full_name, result)
        raise_error_when_type_unmached(metadata_type)

        if session[:read_result].present? && session[:read_result].values.size >= Max_metadata_count
            raise StandardError.new("Cannot read/edit more than 5 meatadata all at once")
        end
        session[:read_result][full_name] = result
    end

    def read_results
        session[:read_result]
    end

    def list_response_json(metadata_type, metadata_list, parent_tree_nodes)
        column_options = [{type: "checkbox", readOnly: false, className: "htCenter htMiddle"}]
        metadata_list.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        {
            :fullName => metadata_type,
            :grid => {:column_options => column_options,
                    :columns => [""] + metadata_list.first.keys, 
                    :rows => metadata_list.map{|hash| [false] + hash.values}
                    },
            :tree => parent_tree_nodes
        }
    end

    def prepare
        metadata_type = params[:metadata_type]
        full_name = params[:name]

        begin
            raise_error_when_type_unmached(metadata_type)
            result = read_metadata(sforce_session, metadata_type, full_name)
            tree_data = format(Metadata::FormatType::Edit, full_name, result)
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
            edit_result = update(session[:read_result][full_name], path, new_text, data_type)
            try_save_session(metadata_type, full_name, edit_result)
            render :json => {:result => "ok"}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:node_id => node_id, :old_text => old_text, :error => ex.message}, :status => 400
        end
    end

    def save
        metadata_type = params[:metadata_type]
        begin
            raise_error_when_type_unmached(metadata_type)
            save_metadata(sforce_session, metadata_type, read_results())
            render :json => {:result => "ok"}, :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def read
        metadata_type = params[:metadata_type]
        full_name = params[:name]
        begin
            result = read_metadata(sforce_session, metadata_type, full_name)
            tree_data = format(Metadata::FormatType::Tree, full_name, result)
            yaml_data = format(Metadata::FormatType::Yaml, full_name, result)
            render :json => read_response_json(full_name, tree_data, yaml_data), :status => 200            
        rescue StandardError => ex
          render :json => {:error => ex.message}, :status => 400
        end
    end

    def read_response_json(full_name, tree_data, yaml_data)
        column_options = []
        yaml_data.header.size.times{column_options << {type: "text", readOnly: true}}
        {
            :fullName => full_name,
            :grid => {:column_options => column_options,
                    :columns => yaml_data.header, 
                    :rows => yaml_data.data
                    },
            :tree => tree_data
        }
    end

    def download
        metadata_type = params[:selected_type]
        selected_record = params[:selected_record]
        export_format = params[:dl_format]
      
        if selected_record.nil?
            respond_download_error("record not selected")
            return
        end

        full_name = selected_record.values[0][Full_name_indxe]

        if full_name.nil?
            respond_download_error("full_name not specified")
            return
        end

        #begin
            result = read_metadata(sforce_session, metadata_type, full_name)
            try_download(export_format, metadata_type, full_name, result)
            set_download_success_cookie(response)
        #rescue StandardError => ex
        #    respond_download_error(ex.message)
        #end
    end

    def try_download(format, metadata_type, full_name, result)
        if format == "csv"
            download_csv(full_name, result)
        elsif format == "yaml"
            download_yaml(full_name, result)
        elsif format == "excel"
            download_excel(metadata_type, full_name, result)
        end
    end

    def set_download_success_cookie(response)
        response.set_cookie("fileDownload", {:value => true, :path => "/"})
    end

    def respond_download_error(message)
        respond_to do |format|
            format.html {render :json => {:error => message, :status => 400}}
            format.text {render :json => {:error => message, :status => 400}}
        end
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

    def download_yaml(full_name, result)
        generator = Generator::MetadataYamlGenerator.new()
        send_data(generator.generate(:full_name => full_name, :data => result),
          :disposition => 'attachment',
          :type => 'application/x-yaml',
          :filename => full_name + '.yml',
          :status => 200
        )
    end

    def download_excel(metadata_type, full_name, result)
        generator = Generator::ExcelGeneratorProxy.generator(metadata_type.to_sym)
        send_data(generator.generate(result),
            :disposition => 'attachment',
            :type => 'application/excel',
            :filename => full_name + '.xlsx',
            :status => 200
        )     
    end
end