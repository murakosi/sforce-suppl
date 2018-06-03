
class MetadataController < ApplicationController

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :read, :download]
    
    Full_name_indxe = 3
    
    def show
        begin
            metadata_types = Metadata::MetadataReader.get_metadata_types(sforce_session)
            html_content = render_to_string :partial => 'metadatalist', :locals => {:data_source => metadata_types}
            render :json => {:target => "#metadata_list", :content => html_content, :error => nil, :status => 200}
        rescue StandardError => ex
            html_content = render_to_string :partial => 'metadatalist', :locals => {:data_source => []}
            render :json => {:target => "#metadata_list", :content => html_content, :error => ex.message, :status => 400}
        end
    end

    def list
        @metadata_type = params[:selected_directory]

        begin
            metadata_list = Metadata::MetadataReader.list_metadata(sforce_session, @metadata_type)
            if metadata_list.nil?
                render :json => {:error => "No data found"}, :status => 400
                return
            end
            
            formatted_list = Metadata::MetadataFormatter.format_metadata_list(metadata_list)
            parent_tree_nodes = Metadata::MetadataFormatter.format_parent_tree_nodes(formatted_list)
            
            render :json => list_response_json(formatted_list, parent_tree_nodes), :status => 200
        rescue StandardError => ex
            p print_error(ex)
            #p ex.backtrace.join("\n")
            #p Rails.backtrace_cleaner.clean(ex.backtrace)
            render :json => {:error => ex.message}, :status => 400
        end
    end   

    def list_response_json(metadata_list, parent_tree_nodes)
        column_options = [{type: "checkbox", readOnly: false, className: "htCenter htMiddle"}]
        metadata_list.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        {
            :fullName => @metadata_type,
            :grid => {:column_options => column_options,
                    :columns => [""] + metadata_list.first.keys, 
                    :rows => metadata_list.map{|hash| [false] + hash.values}
                    },
            :tree => parent_tree_nodes
        }
    end

    def read
        metadata_type = params[:type]
        full_name = params[:name]
        begin
            result = Metadata::MetadataReader.read_metadata(sforce_session, metadata_type, full_name)
            tree_data = Metadata::MetadataFormatter.format(Metadata::MetadataFormatType::Tree, full_name, result)
            yaml_data = Metadata::MetadataFormatter.format(Metadata::MetadataFormatType::Yaml, full_name, result)
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
            result = Metadata::MetadataReader.read_metadata(sforce_session, metadata_type, full_name)
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
        fmetadata_type_sym = metadata_type.to_sym
        generator = Generator::ExcelGeneratorProxy.generator(fmetadata_type_sym)
        send_data(generator.generate(result),
            :disposition => 'attachment',
            :type => 'application/excel',
            :filename => full_name + '.xlsx',
            :status => 200
        )     
    end
end