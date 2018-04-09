require "fileutils"
require "rubyxl"

class DescribeController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]
  
  Key_order = %i[label name type auto_number calculated calculated_formula external_id unique case_sensitive length digits scale precision picklist_values nillable custom] 
  Exclude_header = ["byte_length", "creatable", "defaulted_on_create",
            "deprecated_and_hidden", "filterable", "groupable",
            "id_lookup","name_field","name_pointing", "restricted_picklist",
            "soap_type","sortable","updateable","auto_number","calculated",
            "external_id","unique","case_sensitive",
            "digits","scale","precision"]

  def describe_global
    if !DescribeHelper.is_global_fetched?
      DescribeHelper.describe_global(current_client)
    end
  end
  
  def show
    describe_global
    @sobjects = DescribeHelper.global_result.map{|hash| hash[:name]}
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
      #field_result = describe_result[:fields]
      f1 = describe_result[:fields]
      field_result = get_values(f1)
      @result = {:method => "method", :columns => field_result.first.keys, :rows => field_result.each{ |hash| hash.values}}
      render :json => @result, :status => 200
    #rescue StandardError => ex
    #  render :json => {:error => ex.message}, :status => 400
    #end
  end

  def get_values(field_result)
    field_result.each{ |hash| add_key(hash) }.map{|hash| hash.slice(*Key_order)}
    .map{|hash| change_value(hash)}
    .map{|hash| hash.reject{|k,v| Exclude_header.include?(k.to_s) } }
  end

  def change_value(hash)
    raw_type = hash[:type]

    type = DescribeHelper.field_type_name(hash[:type])
    lengthtype = DescribeHelper.field_length_type(hash[:type])

    if hash[:auto_number]
      hash[:type] = "自動採番"
    elsif hash[:calculated]
      hash[:type] = "数式(" + type + ")"      
    elsif hash[:external_id]
      hash[:type] = "（外部 ID）"
    elsif hash[:unique]
      type += "（ユニーク　"
      if hash[:case_sensitive]
        type += "大文字と小文字を区別する"
      else
        type += "大文字と小文字を区別しない"
      end
      hash[:type] = type
    else
      hash[:type] = type
    end

    if raw_type == "picklist"
      val = hash[:picklist_values].map{|hash| hash[:value]}
      hash[:picklist_values] = val.join("\n")
    end

    if lengthtype == ""
      #hash[:length] = String.valueOf(fieldResult.getLength());
    elsif lengthtype == "NULL"
      hash[:length] = '';
    elsif lengthtype == "INT"
      hash[:length] = hash[:digits].to_s + ',0';
    elsif lengthtype == "DBL"
      precision = hash[:precision]
      scale = hash[:scale]
      size = precision.to_i - scale.to_i
      hash[:length] = size.to_s + ',' + scale.to_s
    end

    hash
  end

  def add_key(hash)
    if !hash.has_key?(:calculated_formula)
      hash.store(:calculated_formula, nil)
    end

    if !hash.has_key?(:external_id)
      hash.store(:external_id, nil)
    end

    if !hash.has_key?(:picklist_values)
      hash.store(:picklist_values, nil)
    end

    if !hash.has_key?(:calculated_formula)
      hash.store(:calculated_formula, nil)
    end

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
