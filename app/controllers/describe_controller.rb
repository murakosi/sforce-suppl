require "fileutils"
require "rubyxl"
require "csv"

class DescribeController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]
  


  def describe_global
    if !DescribeHelper.is_global_fetched?
      DescribeHelper.describe_global(current_client)
    end
  end
  
  def show
    describe_global
    @sobjects = DescribeHelper.global_result.select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
  end

  def change
    describe_global

    object_type = params[:object_type]

    if object_type == "all"
      @sobjects = DescribeHelper.global_result.map{|hash| hash[:name]}
    elsif object_type == "standard"
      @sobjects = DescribeHelper.global_result.reject{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    elsif object_type == "custom"
      @sobjects = DescribeHelper.global_result.select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    else
      raise StandardError.new("Invalid object type parameter")
    end  

    render partial: 'objectlist', locals: {data_source: @sobjects}
  end

  def execute

    sobject = params[:selected_sobject]

    #begin
      describe_result = DescribeHelper.describe(current_client, sobject)
      object_info = get_object_info(describe_result)
      field_result = DescribeHelper.format_field_result(describe_result[:fields])#get_values(describe_result[:fields])
      @result = {:method => object_info, :columns => field_result.first.keys, :rows => field_result.each{ |hash| hash.values}}
      render :json => @result, :status => 200
    #rescue StandardError => ex
    #  render :json => {:error => ex.message}, :status => 400
    #end
  end

  def get_object_info(hash)    
    info = "表示ラベル：" + hash[:label] + "\n" +
           "API参照名：" + hash[:name] + "\n" +
           "プレフィックス：" + hash[:key_prefix]
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
end
