require 'json' 

class SoqlexecuterController < ApplicationController
  include Soql::QueryExecuter

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:query, :update, :delete, :undelete]
  
  Time_format = "%Y/%m/%d %H:%M:%S"

  def show
  end

  def query
    execute_soql(params[:soql], params[:tooling], params[:query_all], params[:tab_id])
  end

  def update
    execute_update(params[:sobject], params[:records], params[:soql_info])
  end
  
  def delete
    execute_delete(params[:ids], params[:soql_info])
  end
  
  def undelete
    execute_undelete(params[:ids], params[:soql_info])
  end

  def execute_soql(soql, tooling, query_all, tab_id)
    begin
      query_result = execute_query(sforce_session, soql, tooling, query_all)
      render :json => response_json(soql, tooling, query_all, tab_id, query_result), :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(soql, tooling, query_all, tab_id, query_result)
    rows = query_result[:records].map{ |hash| hash.values}
    idx = query_result[:id_column_index]
    row_hash = {}
    query_result[:records].each{ |hash| row_hash.merge!({hash.values[idx] => hash.values}) }
    #a = ["<input type='checkbox'>"]

    {
      :soql_info => soql_info(soql, tooling, query_all, tab_id),
      :sobject => query_result[:sobject],
      :records => {
                  #:columns =>  a + query_result[:records].first.keys,
                  :columns =>  query_result[:records].first.keys,
                  :rows => rows,
                  :initial_rows => row_hash,
                  :column_options => query_result[:column_options],
                  :id_column_index => query_result[:id_column_index]
                  }
   }
  end

  def soql_info(soql, tooling, query_all, tab_id)
    {
      :timestamp => " @" + Time.now.strftime(Time_format) + "\r\n",
      :soql => soql,
      :tooling => tooling,
      :query_all => query_all,
      :tab_id => tab_id
    }
  end

  def execute_update(sobject, records, soql_info)
    sobject_records = JSON.parse(records).reject{|k,v| v.size <= 0}

    if sobject_records.size > 0
      sobject_records = sobject_records.map{|k,v| {"Id" => k}.merge!(v)}
      begin
        Service::SoapSessionService.call(sforce_session).update!(sobject, sobject_records)
        render :json => {:done => true, :soql_info => soql_info}, :status => 200
      rescue StandardError => ex
        print_error(ex)
        render :json => {:error => ex.message}, :status => 400
      end
    else
      render :json => {:done => false}, :status => 200
    end

  end
  
  def execute_delete(ids, soql_info)
    if ids.size > 0
      begin
        Service::SoapSessionService.call(sforce_session).delete!(ids)
        render :json => {:done => true, :soql_info => soql_info}, :status => 200
      rescue StandardError => ex
        print_error(ex)
        render :json => {:error => ex.message}, :status => 400
      end
    else
      render :json => {:done => false}, :status => 200
    end
  end
  
  def execute_undelete(ids, soql_info)
    if ids.size > 0
      begin
        Service::SoapSessionService.call(sforce_session).undelete!(ids)
        render :json => {:done => true, :soql_info => soql_info}, :status => 200
      rescue StandardError => ex
        print_error(ex)
        render :json => {:error => ex.message}, :status => 400
      end
    else
      render :json => {:done => false}, :status => 200
    end
  end
  
end
