require 'json' 

class SoqlexecuterController < ApplicationController
  #include Soql::QueryExecuter

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:query, :update, :delete, :undelete]
  
  Time_format = "%Y/%m/%d %H:%M:%S"
  TempIdPrefix = "@"

  def show
  end
  
  def query
    execute_soql(params[:soql], params[:tooling], params[:query_all], params[:tab_id])
  end

  def update
    execute_save(params[:sobject], params[:records], params[:soql_info])
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
      :soql_info => soql_info(query_result[:soql], query_result[:record_count], tooling, query_all, tab_id),
      :sobject => query_result[:sobject],
      :records => {
                  :columns => query_result[:columns],
                  :rows => rows,
                  :initial_rows => row_hash,
                  :column_options => query_result[:column_options],
                  :id_column_index => id_column_index,
                  :size => query_result[:record_count]
                  },
      :tempIdPrefix => TempIdPrefix
    }
  end

  def not_found_response(soql, tooling, query_all, tab_id, query_result)
    {
      :soql_info => soql_info(query_result[:soql], query_result[:record_count], tooling, query_all, tab_id),
      :sobject => query_result[:sobject],
      :records => {
                  :columns => query_result[:columns],
                  :rows => query_result[:records],
                  :initial_rows => {},
                  :column_options => query_result[:column_options],
                  :id_column_index => query_result[:id_column_index],
                  :size => query_result[:record_count]
                  },
      :tempIdPrefix => TempIdPrefix
    }
  end

  def soql_info(soql, record_count, tooling, query_all, tab_id)
    {
      :timestamp => record_count + " rows @" + Time.now.strftime(Time_format) +  "\r\n",
      :soql => soql,
      :tooling => tooling,
      :query_all => query_all,
      :tab_id => tab_id
    }
  end

  def execute_save(sobject, records, soql_info)
    sobject_records = JSON.parse(records).reject{|k,v| v.size <= 0}

    if sobject_records.size <= 0
      render :json => {:done => false}, :status => 200
      return
    end

    upserts = []
    sobject_records.each do |k,v|
      if k.starts_with?(TempIdPrefix)
        upserts << v
      else
        updates = {"Id" => k}.merge!(get_update_fields_hash(v))
        upserts << updates
      end
    end
    
    begin
      execute_upsert(sobject, upserts)
      render :json => {:done => true, :soql_info => soql_info}, :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end

  end
  
  def get_update_fields_hash(fields_hash)
    update_fields = {}
    fields_to_null = []

    fields_hash.each do |field, value|

      if value.nil?
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

  def execute_update(sobject, sobject_records)
    if sobject_records.empty?
      return
    end

    sobject_records = sobject_records.map{|k,v| {"Id" => k}.merge!(v)}
    Service::SoapSessionService.call(sforce_session).update!(sobject, sobject_records)
  end

  def execute_insert(sobject, sobject_records)
    if sobject_records.empty?
      return
    end
      
    Service::SoapSessionService.call(sforce_session).create!(sobject, sobject_records)
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
  
end
