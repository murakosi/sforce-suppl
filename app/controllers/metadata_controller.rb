require "fileutils"
require "rubyXL"
require "csv"

class MetadataController < ApplicationController

  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]
  
  Full_name_sym = :full_name
  Key_order = %i[type id full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

  def show
    @metadata_directory = metadata_client.describe_metadata_objects()
  end

  def response_json(list_result, read_result)
    {:info => @selected_metadata,
     :grid => {:columns => list_result.first.keys, 
               :rows => list_result.each{|hash| hash.values}
              },
     :tree => read_result
    }
  end
  
  def execute
    @selected_metadata = params[:selected_directory]

    begin
      metadata_list = metadata_client.list(@selected_metadata)

      if metadata_list.present?
        list_result = metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|k,v| k[:full_name]}
        read_result = get_read_result(list_result)
        result = response_json(list_result, read_result)
      else
        raise StandardError.new("No results to display")
      end
      
      render :json => result, :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def get_read_result(list_result)
    arr = []
    list_result.each do |hash|
      arr << {:id => hash[:full_name], :parent => "#", :text => "<b>" + hash[:full_name].to_s + "<b>", :children => true }
    end
    arr
  end

  def refresh()
    if params[:id] == "#"
      render :json => "[]", :status => 200
      return 
    end

    selected_metadata = params[:selected_metadata]
    selected_id = params[:id]

    begin
      describe_result = metadata_client.read(selected_metadata, selected_id)[:records]
      parsed = Metadata::Formatter.parse(describe_result, selected_id)
      render :json => parsed, :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
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