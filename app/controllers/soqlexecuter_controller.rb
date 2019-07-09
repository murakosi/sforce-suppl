require 'json' 

class SoqlexecuterController < ApplicationController
  include Soql::QueryExecuter

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:query, :update]
  
  Time_format = "%Y/%m/%d %H:%M:%S"

  def show
  end

  def query
    execute_soql(params[:soql], params[:tooling])
  end

  def update
    execute_update(params[:sobject], params[:records])
  end

  def execute_soql(soql, tooling)
    begin
      query_result = execute_query(sforce_session, soql, tooling)
      render :json => response_json(soql, tooling, query_result), :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(soql, tooling, query_result)
    rows = query_result[:records].map{ |hash| hash.values}
    idx = query_result[:id_column_index]
    row_hash = {}
    query_result[:records].each{ |hash| row_hash.merge!({hash.values[idx] => hash.values}) }
    #a = ["<input type='checkbox'>"]

    {
      :soql_info => soql_info(soql, tooling),
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

  def soql_info(soql, tooling)
    {
      :timestamp => " @" + Time.now.strftime(Time_format) + "\r\n",
      :soql => soql,
      :tooling => tooling
    }
  end

  def execute_update(sobject, records)
    p sobject
    p JSON.parse(records)
    p sobject_records = JSON.parse(records).map{|k,v| {"Id" => k}.merge!(v)}
    render :json => nil, :status => 200
  end

end
