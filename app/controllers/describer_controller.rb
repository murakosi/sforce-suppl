require "fileutils"
require "rubyxl"

class DescriberController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]

  @result = nil
  attr_reader :keep
  
  def show
    puts params
    res = current_client.describe_global()
    #puts res.each{|v| v.to_s}
    @keep = Array.new
    @keep = res[:sobjects].map { |sobject| {:name => sobject[:name], :cus => sobject[:custom]} }

    @sobjects = @keep.map{|hash| hash[:name]}
    #@sobjects = [{"Railsの基礎" => "rails_base", "Rubyの基礎" => "ruby_base"}]
  end

  def change
    puts @keep.class
    #@sobjects = @keep.reject{|h| !h[:custom] }.map{|h| h[:name]}
    res = current_client.describe_global()
    @keep = res[:sobjects].map { |sobject| {:name => sobject[:name], :cus => sobject[:custom]} }

    @sobjects = @keep.reject{|h| !h[:custom] }.map{|h| h[:name]}

    render :json => @sobjects, :status => 200
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
