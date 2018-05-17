require "fileutils"


class DescribeController < ApplicationController
  include Describe::DescribeExecuter
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute, :download]

  def show
    @sobjects = describe_global(sforce_session).select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    render partial: 'objectlist', locals: {data_source: @sobjects}
  end

  def change
    sobject_type = params[:object_type]

    if sobject_type == "all"
      sobjects = get_sobject_names(sforce_session, Describe::SobjectType::All)
    elsif sobject_type == "standard"
      sobjects = get_sobject_names(sforce_session, Describe::SobjectType::Standard)
    elsif sobject_type == "custom"
      sobjects = get_sobject_names(sforce_session, Describe::SobjectType::Custom)
    else
      raise StandardError.new("Invalid object type parameter")
    end  

    render partial: 'objectlist', locals: {data_source: sobjects}
    #render :json => sobjects, :status => 200
  end

  def execute

    sobject = params[:selected_sobject]

    #begin
      field_result = describe_field(sforce_session, sobject)
      sobject_info = get_sobject_info(field_result)
      formatted_result = format_field_result(sobject, field_result[:fields])

      result = {:method => sobject_info, :columns => formatted_result.first.keys, :rows => formatted_result.each{ |hash| hash.values}}

      render :json => result, :status => 200
    #rescue StandardError => ex
    #  render :json => {:error => ex.message}, :status => 400
    #end
  end

  def get_sobject_info(field_result)
      info = "表示ラベル：" + field_result[:label] + "\n" +
          "API参照名：" + field_result[:name] + "\n" +
          "プレフィックス：" + field_result[:key_prefix]
  end
  
  def download
    sobject = params[:selected_sobject]

    field_result = describe_field(sforce_session, sobject)
    formatted_result = format_field_result(sobject, field_result[:fields])

    if params[:format] == "csv"
      download_csv(sobject, formatted_result)
    else
      download_excel(sobject, formatted_result)
    end
  end

  def download_csv(sobject, field_result)
    generator = Generator::DescribeCsvGenerator.new(Encoding::SJIS, "\r\n", true)
    send_data(generator.generate(:data => field_result),
      :disposition => 'attachment',
      :type => 'text/csv',
      :filename => sobject + '.csv',
      :status => 200
    )
  end

  def download_excel(sobject, field_result)
=begin
    source_excel = "./resources/book1.xlsx"

    output_excel = "./output/book1_copy.xlsx"

    FileUtils.cp(source_excel, output_excel)

    workbook = RubyXL::Parser.parse(output_excel)
    sheet = workbook.first

    row = 2
    field_result.each do | values |
      values.each do | k, v |
        sheet.add_cell(row, Describe::DescribeConstants.column_number(k), v)
      end
      row += 1
    end

    workbook.write(output_excel)
=end
    generator = Generator::ExcelGeneratorProxy.generator(:DescribeResult)
    send_data(generator.generate(field_result),#workbook.stream.read,
      :disposition => 'attachment',
      :type => 'application/excel',
      :filename => sobject + '.xlsx',
      :status => 200
    )
    
    #FileUtils.rm(output_excel)
  end
end
