require 'json' 

class SoqlexecuterController < ApplicationController

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:query, :upsert, :delete, :undelete]
  
  Time_format = "%Y/%m/%d %H:%M:%S"
  Temp_id_prefix = "@"

  def show
  end
  
  def query
    execute_soql(params[:soql], params[:tooling], params[:query_all], params[:tab_id])
  end

  def upsert
    new_param = params.permit!.to_h
    
    execute_save(new_param[:sobject], new_param[:records], new_param[:soql_info])
  end
  
  def delete
    execute_delete(params[:ids], params[:soql_info])
  end
  
  def undelete
    execute_undelete(params[:ids], params[:soql_info])
  end

  def execute_soql(soql, tooling, query_all, tab_id)
    begin
      query_result = Soql::QueryExecuter.execute_query(sforce_session, soql, tooling, query_all)
      render :json => response_json(soql, tooling, query_all, tab_id, query_result), :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(soql, tooling, query_all, tab_id, query_result)
    if query_result[:records].size > 0
      normal_response(soql, tooling, query_all, tab_id, query_result)
    else
      not_found_response(soql, tooling, query_all, tab_id, query_result)
    end
  end

  def normal_response(soql, tooling, query_all, tab_id, query_result)
    rows = query_result[:records].map{ |hash| hash.values}
    id_column_index = query_result[:id_column_index]
    row_hash = {}
    if id_column_index.present?
      query_result[:records].each{ |hash| row_hash.merge!({hash.values[id_column_index] => hash.values}) }
    end

    {
      :soql_info => soql_info(query_result[:soql], query_result[:record_count], tooling, query_all, tab_id, query_result[:sobject]),
      :sobject => query_result[:sobject],
      :records => {
                  :columns => query_result[:columns],
                  :rows => rows,
                  :initial_rows => row_hash,
                  :column_options => query_result[:column_options],
                  :id_column_index => id_column_index,
                  :size => query_result[:record_count]
                  },
      :tempIdPrefix => Temp_id_prefix
    }
  end

  def not_found_response(soql, tooling, query_all, tab_id, query_result)
    {
      :soql_info => soql_info(query_result[:soql], query_result[:record_count], tooling, query_all, tab_id, query_result[:sobject]),
      :sobject => query_result[:sobject],
      :records => {
                  :columns => query_result[:columns],
                  :rows => query_result[:records],
                  :initial_rows => {},
                  :column_options => query_result[:column_options],
                  :id_column_index => query_result[:id_column_index],
                  :size => query_result[:record_count]
                  },
      :tempIdPrefix => Temp_id_prefix
    }
  end

  def soql_info(soql, record_count, tooling, query_all, tab_id, sobject)
    if soql.nil?
      {
        :timestamp => "sObject : " + sobject,
        :soql => soql,
        :tooling => tooling,
        :query_all => query_all,
        :tab_id => tab_id
      }
    else
      {
        :timestamp => sobject + " : " + record_count + " rows @" + Time.now.in_time_zone('Tokyo').strftime(Time_format),
        :soql => soql,
        :tooling => tooling,
        :query_all => query_all,
        :tab_id => tab_id
      }
    end
  end

  def execute_save(sobject, records, soql_info)
    sobject_records = JSON.parse(records).reject{|k,v| v.size <= 0}

    if sobject_records.size <= 0
      render :json => {:done => false}, :status => 200
      return
    end

    upserts = []
    sobject_records.each do |k,v|
      if k.starts_with?(Temp_id_prefix)
        upserts << v
      else
        upserts << {"Id" => k}.merge(get_update_fields_hash(v))
      end
    end
    
    begin
      if soql_info["soql"].empty?
        key_map = execute_insert(sobject, sobject_records.keys, upserts)
        soql_info.store(:key_map, key_map)
      else
        execute_upsert(sobject, upserts)
      end
      render :json => {:done => true, :soql_info => soql_info}, :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end

  end

  def execute_insert(sobject, ids, sobject_records)
    result = Service::SoapSessionService.call(sforce_session).upsert!(sobject, "Id", sobject_records)
    if result.is_a?(Hash)
      result = [result]
    end
    map = {}
    ids.each_with_index do |str, i|
      map.store(str, result[i][:id])
    end
    map
  end
  
  def get_update_fields_hash(fields_hash)
    update_fields = {}
    fields_to_null = []

    fields_hash.each do |field, value|
      if value.empty?
        fields_to_null << field
      else
        update_fields.store(field, value)
      end

    end

    if fields_to_null.size > 0
      update_fields.store(:fields_to_null, fields_to_null)
    end
    
    update_fields
  end

  def execute_upsert(sobject, sobject_records)
    Service::SoapSessionService.call(sforce_session).upsert!(sobject, "Id", sobject_records)
  end
  
  def execute_delete(ids, soql_info)
    if ids.size <= 0
      render :json => {:done => false}, :status => 200
      return
    end

    begin
      Service::SoapSessionService.call(sforce_session).delete!(ids)
      render :json => {:done => true, :soql_info => soql_info}, :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end     

  end
  
  def execute_undelete(ids, soql_info)
    if ids.size <= 0
      return
    end

    begin
      Service::SoapSessionService.call(sforce_session).undelete!(ids)
      render :json => {:done => true, :soql_info => soql_info}, :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end

  end

  def create
    sobject = params[:sobject]
    tab_id = params[:tab_id]
    raw_fields = params[:fields]
    separator = params[:separator]

    if separator == "comma"
      fields = raw_fields.split(",").map(&:strip).map(&:upcase)
    else
      fields = raw_fields.split("\n").map(&:strip).map(&:upcase)
    end

    id_column_index = 0
    if !fields.include?("ID")
      fields = ["ID"] + fields
    else
      id_column_index = fields.index{|field| field == "ID"}
    end

    render :json => create_response_json(sobject, tab_id, fields, id_column_index), :status => 200

  end

  def create_response_json(sobject, tab_id, columns, id_column_index)
    
    column_options = []
    columns.each do |column|
      if column.upcase == "ID"
        column_options << {readOnly: true, type: "text"}
      else
        column_options << {readOnly: false, type: "text"}
      end
    end

    {
      :soql_info => soql_info("", "0", false, false, tab_id, sobject),
      :sobject => sobject,
      :records => {
                  :columns => columns,
                  :rows => [],
                  :initial_rows => {},
                  :column_options => column_options,
                  :id_column_index => id_column_index,
                  :size => 0
                  },
      :tempIdPrefix => Temp_id_prefix
    }    

  end
  
end
