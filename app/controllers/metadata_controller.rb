require "fileutils"
require "rubyxl"
require "csv"

class MetadataController < ApplicationController
  include Metadata

  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]
  
  Full_name_sym = :full_name
  Key_order = %i[type id full_name file_name created_date created_by_id created_by_name last_modified_date last_modified_by_id last_modified_by_name monegeable_state]

  def show
    @metadata_directory = metadata_client.describe_metadata_objects()
    #@metadata_directory = ["a","b"]
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
    #@selected_metadata = "ApprovalProcess"

    #begin
      metadata_list = metadata_client.list(@selected_metadata)

      if metadata_list.present?
        list_result = metadata_list.map{ |hash| hash.slice(*Key_order)}.sort_by{|k,v| k[:full_name]}
        #read_result = refresh(list_result)
        read_result = get_read_result(list_result)
        result = response_json(list_result, read_result)
      else
        raise StandardError.new("No results to display")
      end
      
      render :json => result, :status => 200
    #rescue StandardError => ex
      #render :json => {:error => ex.message}, :status => 400
    #end
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

    describe_result = metadata_client.read(selected_metadata, selected_id)[:records]
    parsed = Metadata::Formatter.parse(describe_result, selected_id)#parse_hash(describe_result, selected_id)
    render :json => parsed, :status => 200
  end


=begin
  def download
    if params[:format] == "csv"
      download_csv()
    else
      download_excel()
    end
  end

  def download_csv
    csv_date = CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
      csv_column_names = DescribeHelper.formatter_object_result.first.keys
      csv << csv_column_names
      DescribeHelper.formatter_object_result.each do | hash |
          csv << hash.values
      end
    end
    send_data(csv_date, filename: "abc.csv")
  end

  def download_excel

    if !DescribeHelper.is_sobject_fetched?
      return
    end

    source_excel = "./lib/assets/book1.xlsx"

    output_excel = "./Output/book1_copy.xlsx"

    FileUtils.cp(source_excel, output_excel)

    workbook = RubyXL::Parser.parse(output_excel)
    sheet = workbook.first

    row = 2
    DescribeHelper.formatter_object_result.each do | values |
      values.each do | k,v |
        sheet.add_cell(row, DescribeConstants.column_number(k), v)
      end
      row += 1
    end

    workbook.write(output_excel)

    #ファイルの出力
    send_data(workbook.stream.read,
      :disposition => 'attachment',
      :type => 'application/excel',
      :filename => 'abc.xlsx',
      :status => 200
    )
    
    FileUtils.rm(dest)
  end
=end
end