require "fileutils"
require "rubyXL"
require "csv"

class DescribeController < ApplicationController
  include Describe::DescribeExecuter
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute, :download]

  def show
    @sobjects = describe_global(sforce_session).select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    render partial: 'objectlist', locals: {data_source: @sobjects}
  end

  def change
    object_type = params[:object_type]

    if object_type == "all"
      sobjects = describe_global(sforce_session).map{|hash| hash[:name]}
    elsif object_type == "standard"
      sobjects = describe_global(sforce_session).reject{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    elsif object_type == "custom"
      sobjects = describe_global(sforce_session).select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
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

  def download
    sobject = params[:selected_sobject]
    p params
    field_result = formatted_field_result(sobject)

    if !field_result.present?
      return
    end

    if params[:format] == "csv"
      download_csv(sobject, field_result)
    else
      download_excel(sobject, field_result)
    end
  end

  def download_csv(sobject, field_result)
    csv_data = CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
      csv_column_names = field_result.first.keys
      csv << csv_column_names
      field_result.each do | hash |
          csv << hash.values
      end
    end

    send_data(csv_data,
      :disposition => 'attachment',
      :type => 'text/csv',
      :filename => sobject + '.csv',
      :status => 200
    )
  end

  def download_excel(sobject, field_result)

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

    send_data(workbook.stream.read,
      :disposition => 'attachment',
      :type => 'application/excel',
      :filename => sobject + '.xlsx',
      :status => 200
    )
    
    FileUtils.rm(output_excel)
  end
end
