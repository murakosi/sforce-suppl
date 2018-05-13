require "fileutils"
require "rubyXL"
require "csv"

class DescribeController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]

  def show
    sobjects = Describe::Describer.describe_global.select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    render partial: 'objectlist', locals: {data_source: sobjects}
  end

  def change

    object_type = params[:object_type]

    if object_type == "all"
      sobjects = Describe::Describer.describe_global(current_client).map{|hash| hash[:name]}
    elsif object_type == "standard"
      sobjects = Describe::Describer.describe_global(current_client).reject{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    elsif object_type == "custom"
      sobjects = Describe::Describer.describe_global(current_client).select{|hash| hash[:is_custom] }.map{|hash| hash[:name]}
    else
      raise StandardError.new("Invalid object type parameter")
    end  

    render partial: 'objectlist', locals: {data_source: sobjects}
  end

  def execute

    sobject = params[:selected_sobject]

    #begin
      field_result = Describe::Describer.describe_field(current_client, sobject)
      sobject_info = Describe::Describer.get_sobject_info(field_result)
      formatted_result = Describe::Describer.format_field_result(field_result[:fields])

      result = {:method => sobject_info, :columns => formatted_result.first.keys, :rows => formatted_result.each{ |hash| hash.values}}

      render :json => result, :status => 200
    #rescue StandardError => ex
    #  render :json => {:error => ex.message}, :status => 400
    #end
  end

  def download
    if !DescribeHelper.described_object_name.present?
      return
    end

    if params[:format] == "csv"
      download_csv()
    else
      download_excel()
    end
  end

  def download_csv
    csv_data = CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
      csv_column_names = Describe::Describer.formatted_field_result.first.keys
      csv << csv_column_names
      Describe::Describer.formatted_field_result.each do | hash |
          csv << hash.values
      end
    end
    #send_data(csv_date, filename: "abc.csv")
    send_data(csv_data,
      :disposition => 'attachment',
      :type => 'text/csv',
      :filename => Describe::Describer.described_object_name + '.csv',
      :status => 200
    )
  end

  def download_excel

    source_excel = "./resources/book1.xlsx"

    output_excel = "./output/book1_copy.xlsx"

    FileUtils.cp(source_excel, output_excel)

    workbook = RubyXL::Parser.parse(output_excel)
    sheet = workbook.first

    row = 2
    Describe::Describer.formatted_field_result.each do | values |
      values.each do | k,v |
        sheet.add_cell(row, DescribeConstants.column_number(k), v)
      end
      row += 1
    end

    workbook.write(output_excel)

    send_data(workbook.stream.read,
      :disposition => 'attachment',
      :type => 'application/excel',
      :filename => Describe::Describer.described_object_name + '.xlsx',
      :status => 200
    )
    
    FileUtils.rm(output_excel)
  end
end
