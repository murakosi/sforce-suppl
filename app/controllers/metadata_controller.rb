require "fileutils"
require "rubyXL"
require "csv"

class MetadataController < ApplicationController

  before_action :require_sign_in!

  protect_from_forgery :except => [:list, :read]

  Metadata_type_column_index = 1
  Full_name_column_index = 3

  def show
    @metadata_directory = metadata_client.describe_metadata_objects()
  end

  def execute_response_json(list_result, read_result)
    column_options = [{type: "checkbox", readOnly: false, className: "htCenter htMiddle"}]
    list_result.first.keys.size.times{column_options << {type: "text", readOnly: true}}
    {:info => @selected_metadata,
     :grid => {:column_options => column_options,
               :columns => [""] + list_result.first.keys, 
               :rows => list_result.map{|hash| [false] + hash.values}
              },
     :tree => read_result
    }
  end

  def read_response_json(read_result)
    column_options = []
    read_result.header.size.times{column_options << {type: "text", readOnly: true}}
    {:info => "read",
     :grid => {:column_options => column_options,
               :columns => read_result.header, 
               :rows => read_result.data
              }
    }
  end

  def list
    @selected_metadata = params[:selected_directory]

    begin
      metadata_list = metadata_client.list(@selected_metadata)

      if metadata_list.present?
        list_result = Metadata::Formatter.format_metadata_list(metadata_list)
        tree_nodes = Metadata::Formatter.format_tree_nodes(list_result)
        result = execute_response_json(list_result, tree_nodes)
      else
        raise StandardError.new("No results to display")
      end    
      render :json => result, :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def read
    rows = params[:data]
    p rows

    if rows.nil?
      render :json => {:error => "Row data is empty"}, :status => 400
      return
    end

    row_data = rows.values.first
    metadata_type = row_data[Metadata_type_column_index]
    full_name = row_data[Full_name_column_index]

    #begin
      result = execute_read_metadata(metadata_type, full_name)
      render :json => read_response_json(result.raw_data), :status => 200            
    #rescue StandardError => ex
    #  render :json => {:error => ex.message}, :status => 400
    #end
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
    csv_date = CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
      csv_column_names = Metadata::Formatter.metadata_store.csv_header
      csv << csv_column_names
      Metadata::Formatter.metadata_store.key_store.keys.each do | k, v |
          arr = []
          arr << k
          v.each{|item| item.each{|k, v| arr << v}}
          csv << arr
      end
    end
    send_data(csv_date, filename: "abc.csv")
  end

  def download_excel

    #if !Metadata::Formatter.metadata_store.stored?
    #  return
    #end
    describe_result = metadata_client.read("ApprovalProcess", "Order__c.Qty_under_10")[:records]
    parsed = Metadata::Formatter.parse(describe_result, "Order__c.Qty_under_10")

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
=begin 
    begin
      source_excel = "./resources/book2.xlsx"

      output_excel = "./output/book2_copy.xlsx"

      FileUtils.cp(source_excel, output_excel)

      workbook = RubyXL::Parser.parse(output_excel)
      sheet = workbook.first

      Metadata::Formatter.mapping.each do | map |
        map.each do | key, value |
          akey = Metadata::Formatter.metadata_store.key_store.keys[k]
          bkey = akey.first
          row = value[:r].to_i - 1
          col = value[:c].to_i - 1
          sheet[row][col].change_contents(bkey[:value])
        end
      end

      workbook.write(output_excel)

      #ファイルの出力
      send_data(workbook.stream.read,
        :disposition => 'attachment',
        :type => 'application/excel',
        :filename => 'approval.xlsx',
        :status => 200
      )
      
    rescue StandardError => ex
      raise ex
      return
    ensure
      FileUtils.rm(output_excel)
    end
=end
  end

end