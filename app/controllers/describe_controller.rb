require "fileutils"
require "rubyxl"

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
    object_type = hash[:custom] ? "カスタムオブジェクト" : "標準オブジェクト"
    info = object_type + "\n" +
           "表示ラベル：" + hash[:label] + "\n" +
           "API参照名：" + hash[:name] + "\n" +
           "プレフィックス：" + hash[:key_prefix]
  end

  def download

    src_path = "./lib/assets/book1.xlsx"

    dest = "./Output/book1_copy.xlsx"

    FileUtils.cp(src_path, dest)

    workbook = RubyXL::Parser.parse(dest)
    sheet = workbook.first

    for row in 2..5
      for col in 0..6
        sheet.add_cell(row, col , "row" + row.to_s + "," + "col" + col.to_s)
      end
    end

    workbook.write(dest)

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
