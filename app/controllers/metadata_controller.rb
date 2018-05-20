require "fileutils"
require "rubyXL"
require "csv"

class MetadataController < ApplicationController
    helper_method :list

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :read, :download]

    Metadata_type_column_index = 1
    Full_name_column_index = 3
    
    def show
        metadata_list = Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
        html_content = render_to_string :partial => 'metadatalist', :locals => {:data_source => metadata_list}
        render :json => {:target => "#metadata_list", :content => html_content} 
    end

    def list
        @selected_metadata = params[:selected_directory]

        #begin
            metadata_list = metadata_client.list(@selected_metadata)
            list_result = Metadata::Parser.format_metadata_list(metadata_list)
            tree_nodes = Metadata::Parser.format_tree_nodes(list_result)
 
            render :json => list_response_json(list_result, tree_nodes), :status => 200
        #rescue StandardError => ex
        #    render :json => {:error => ex.message}, :status => 400
        #end
    end
    
    def list_response_json(list_result, tree_nodes)
        column_options = [{type: "checkbox", readOnly: false, className: "htCenter htMiddle"}]
        list_result.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        {
            :fullName => @selected_metadata,
            :grid => {:column_options => column_options,
                    :columns => [""] + list_result.first.keys, 
                    :rows => list_result.map{|hash| [false] + hash.values}
                    },
            :tree => tree_nodes
        }
    end

    def read
        metadata_type = params[:type]
        full_name = params[:name]
        #begin
            result = execute_read_metadata(metadata_type, full_name)
            render :json => read_response_json(full_name, result.display_data, result.raw_data), :status => 200            
        #rescue StandardError => ex
        #  render :json => {:error => ex.message}, :status => 400
        #end
    end

    def read_response_json(full_name, tree_data, raw_data)
        column_options = []

        raw_data.header.size.times{column_options << {type: "text", readOnly: true}}
        {
            :fullName => full_name,
            :grid => {:column_options => column_options,
                    :columns => raw_data.header, 
                    :rows => raw_data.data
                    },
            :tree => tree_data
        }
    end

    def refresh
        if params[:id] == "#"
            render :json => "[]", :status => 200
            return 
        end

        selected_metadata = params[:selected_metadata]
        selected_id = params[:id]

        #begin
            result = execute_read_metadata(selected_metadata, selected_id)
            render :json => result.display_data, :status => 200
        #rescue StandardError => ex
        #  render :json => {:error => ex.message}, :status => 400
        #end
    end

    def execute_read_metadata(metadata_type, full_name)
        if Metadata::Parser.metadata_store.stored?(full_name)
            Metadata::Parser.metadata_store[full_name]
        else
            describe_result = metadata_client.read(metadata_type, full_name)[:records]
            Metadata::Parser.parse(describe_result, full_name)
        end
    end

    def download
        if Metadata::Parser.metadata_store.current_full_name.nil? && params[:format] != "excel"
            return
        end
        
        if params[:format] == "csv"
            download_csv()
        elsif params[:format] == "yaml"
            download_yaml()
        elsif params[:format] == "excel"
            download_excel()
        end
    end

    def download_yaml()
        yaml = []
        full_name = Metadata::Parser.metadata_store.current_full_name
        Metadata::Parser.metadata_store[full_name].raw_data.data.each do | data |
            yaml << data[0].to_s + ":"
            yaml << "    row: "
            yaml << "    column: "
            yaml << "    multi: false"
            yaml << "    start_row: 0"
            yaml << "    end_row: 0"
            yaml << "    join:"
        end
        send_data(yaml.join("\n"), filename: Metadata::Parser.metadata_store[full_name].raw_data.type + ".yaml")        
    end

    def download_csv
        full_name = Metadata::Parser.metadata_store.current_full_name
        csv_date = CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
            csv_column_names = Metadata::Parser.metadata_store[full_name].raw_data.header
            csv << csv_column_names
            Metadata::Parser.metadata_store[full_name].raw_data.data.each do | data |
                csv << data
            end
        end
        send_data(csv_date, filename: full_name + ".csv")
    end

    def download_excel

        #if !Metadata::Formatter.metadata_store.stored?
        #  return
        #end
        describe_result = metadata_client.read("ApprovalProcess", "Order__c.Qty_under_10")[:records]
        parsed = Metadata::Parser.parse(describe_result, "Order__c.Qty_under_10")

        exporter = Metadata::HelperProxy.get_exporter("ApprovalProcess", Metadata::Parser.metadata_store["Order__c.Qty_under_10"].export_data)
        begin
            result = exporter.export()
            if result.nil?
                return
            end
            send_data(result.data,
                :disposition => 'attachment',
                :type => 'application/excel',
                :filename => result.file_name,
                :status => 200
            )
        rescue StandardError => ex
            raise ex
        end
    end

end