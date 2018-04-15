require "fileutils"
require "rubyxl"
require "csv"

class MetadataController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]

  def describe_global
    if !DescribeHelper.is_global_fetched?
      DescribeHelper.describe_global(current_client)
    end
  end
  
  def show
    #describe_global
    @metadata_directory = metadata_client.metadata_objects
    @metadata_child = []
  end

  def change
    #directory_name = params[:directory_name]

    #@metadata_child = metadata_client.metadata_objects.select{|k,v| k == directory_name}.values.to_a
    @metadata_child = []
    render partial: 'metadata_child', locals: {data_source: @metadata_child}
  end

  def refresh
    metadata = params[:selected_directory]

    metadata_list = metadata_client.list(metadata).map{ |k,v| k[Full_name_sym]}

    describe_result = []
      
    metadata_list.each do |hash|
      describe_result << metadata_client.read(metadata,hash)[:records]
    end

    render :json => parse(metadata, describe_result), :status => 200
  end

  Full_name_sym = :full_name
  def get_id(parent, current)
    parent.to_s + "-" + current.to_s
  end

  def get_text(key, value = nil)
    if value.nil?
      "<b>" + key.to_s + "</b>"
    else
      "<b>" + key.to_s + "</b>: " + value.to_s
    end
  end

  def parse(type, arr = [])
    newa = []
    arr.each_with_index do |hash, i|
      newa |= parseHash(hash, "full_name" + i.to_s)
    end
    newa
  end

  def parseHash(a, full_name_sym)
    p = []
    a.each do |k, v|
      if v.is_a?(Hash)
        p << {:id => get_id(full_name_sym, k), :parent => full_name_sym, :text => get_text(k) }
        parse_child(p, get_id(full_name_sym, k), v)
      elsif v.is_a?(Array)
        p << {:id => get_id(full_name_sym, k), :parent => full_name_sym, :text => get_text(k) }
        v.each_with_index do |val, idx|
          p << {:id => get_id(full_name_sym, k.to_s + idx.to_s), :parent => get_id(full_name_sym, k), :text => get_text(k, idx)}
          parse_child(p, get_id(full_name_sym, k.to_s + idx.to_s), val)
        end
      elsif k == Full_name_sym
        p << {:id => full_name_sym, :parent => "#", :text => get_text(v)}
      else
        p << {:id => get_id(full_name_sym, k), :parent => full_name_sym, :text => get_text(k, v)}
      end
    end
    p
  end

  def parse_child(a = [], parent_key, value)

    value.each do |k, v|
      if v.is_a?(Hash)
        a << {:id => get_id(parent_key, k), :parent => parent_key, :text => get_text(k)}
        #v.each do |nk, nv|
          parse_child(a, get_id(parent_key, k), v)
        #end
      elsif v.is_a?(Array)        
        v.each do |val|
          if val.is_a?(Hash) || val.is_a?(Array)
            a << {:id => get_id(parent_key, k), :parent => parent_key, :text => get_text(k)}
            parse_child(a, get_id(parent_key, k), val)
          else
            a << {:id => get_id(parent_key, val), :parent => parent_key, :text => get_text(val)}
          end
        end
      else
        a << {:id => get_id(parent_key, k), :parent => parent_key, :text => get_text(k, v)}
      end
    end

  end

  def execute

    metadata = params[:selected_directory]

    begin
      describe_result = metadata_client.list(metadata)
      @result = {:method => "meta", :columns => describe_result.keys, :rows => describe_result.values}
      render :json => @result, :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end
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