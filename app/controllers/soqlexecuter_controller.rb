
class SoqlexecuterController < ApplicationController
  include Soql::QueryExecuter

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:execute]
  
  Time_format = "%Y/%m/%d %H:%M:%S"

  def show
  end

  def execute
    execute_soql(params[:soql], params[:tooling])
  end

  def execute_soql(soql, tooling)
    begin
      query_result = execute_query(sforce_session, soql, tooling)
      render :json => response_json(soql, query_result), :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(soql, query_result)
    rows = query_result[:records].map{ |hash| hash.values}
    {
      :soql_info => soql_info(soql),
      :soql => soql,
      :sobject => query_result[:sobject],
      :records => {
                  :columns => query_result[:records].first.keys,
                  :rows => rows,
                  :initial_rows => rows,
                  :column_options => query_result[:column_options]
                  }
   }
  end

  def soql_info(soql)
    " @" + Time.now.strftime(Time_format) + "\r\n" + soql
  end

end
