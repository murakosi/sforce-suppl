require "fileutils"
require "rubyxl"
#require "DescriberHelper"

class DescribeController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]

  #@@global_result = Array.new

  attr_reader :keep
  
  def describe_global
    if !DescriberHelper.is_global_fetched?
      DescriberHelper.describe_global(current_client)
    end
  end
  
  def show
    describe_global
    @sobjects = DescriberHelper.global_result.map{|hash| hash[:name]}
  end

  def change
    @sobjects = DescriberHelper.global_result.select{|h| h[:name] == 'Account' }.map{|h| h[:name]}

    render partial: 'objectlist', locals: {data_source: @sobjects}
  end

  def execute

    @result = nil

    sobject = params[:selected_sobject]

    begin
      describe_result = current_client.describe(sobject)
      field_result = describe_result[:fields]
      @result = {:method => "method", :columns => field_result.first.keys, :rows => field_result.each{ |hash| hash.values}}

      render :json => @result, :status => 200
    rescue StandardError => ex

      render :json => {:error => ex.message}, :status => 400
    end
  end

  def get_values(field_result)
    #key_order = %i[b a]
    #field_result.each{ |hash| hash.values}}.slice(*key_order)
  end

  def download

    if @result.nil?
      render 'back'
      return
    end

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
