require "fileutils"
require "rubyXL"
require "csv"

class MetadataController < ApplicationController

    before_action :require_sign_in!

    protect_from_forgery :except => [:list, :read, :download]

    Metadata_type_column_index = 1
    Full_name_column_index = 3

    def show
        @metadata_directory = metadata_client.describe_metadata_objects()
    end

    def list
        @selected_metadata = params[:selected_directory]

        begin
            metadata_list = metadata_client.list(@selected_metadata)
            list_result = Metadata::Formatter.format_metadata_list(metadata_list)
            tree_nodes = Metadata::Formatter.format_tree_nodes(list_result)
 
            render :json => list_response_json(list_result, tree_nodes), :status => 200
        rescue StandardError => ex
            render :json => {:error => ex.message}, :status => 400
        end
    end
    
    def list_response_json(list_result, read_result)
        column_options = [{type: "checkbox", readOnly: false, className: "htCenter htMiddle"}]
        list_result.first.keys.size.times{column_options << {type: "text", readOnly: true}}
        {
            :info => @selected_metadata,
            :grid => {:column_options => column_options,
                    :columns => [""] + list_result.first.keys, 
                    :rows => list_result.map{|hash| [false] + hash.values}
                    },
            :tree => read_result
        }
    end

    def read
        rows = params[:data]

        if rows.nil?
            render :json => {:error => "Row data is empty"}, :status => 400
            return
        end

        row_data = rows.values.first
        metadata_type = row_data[Metadata_type_column_index]
        full_name = row_data[Full_name_column_index]

        #begin
            result = execute_read_metadata(metadata_type, full_name)
            render :json => read_response_json(full_name, result.raw_data), :status => 200            
        #rescue StandardError => ex
        #  render :json => {:error => ex.message}, :status => 400
        #end
    end

    def read_response_json(node_id, raw_data)
        column_options = []
        raw_data.header.size.times{column_options << {type: "text", readOnly: true}}
        {
            :info => "read",
            :grid => {:column_options => column_options,
                    :columns => raw_data.header, 
                    :rows => raw_data.data
                    },
            :node => node_id
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
        if Metadata::Formatter.metadata_store.stored?(full_name)
            Metadata::Formatter.metadata_store[full_name]
        else
            describe_result = metadata_client.read(metadata_type, full_name)[:records]
            Metadata::Formatter.format(describe_result, full_name)
        end
    end

    def download
        if params[:format] == "csv"
            download_csv()
        else
            download_excel()
        end
    end

    def download_csv
        if Metadata::Formatter.metadata_store.current_full_name.nil?
            return
        end

        full_name = Metadata::Formatter.metadata_store.current_full_name
        csv_date = CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
            csv_column_names = Metadata::Formatter.metadata_store[full_name].raw_data.header
            csv << csv_column_names
            Metadata::Formatter.metadata_store[full_name].raw_data.data.each do | data |
                csv << data
            end
        end
        send_data(csv_date, filename: "abc.csv")
    end

    def download_excel

        #if !Metadata::Formatter.metadata_store.stored?
        #  return
        #end
        describe_result = metadata_client.read("ApprovalProcess", "Order__c.Qty_under_10")[:records]
        parsed = Metadata::Formatter.format(describe_result, "Order__c.Qty_under_10")

        exporter = Metadata::HelperProxy.get_exporter("ApprovalProcess", Metadata::Formatter.metadata_store.key_store)
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