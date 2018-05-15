
class SoqlexecuterController < ApplicationController
  include Soql::QueryExecuter
  before_action :require_sign_in!
  
  protect_from_forgery :except => [:execute]
  
  def show
  end

  def execute
    execute_soql(params[:soql]) if params[:soql].present?
  end

  def execute_soql(soql)
    begin
      query_result = execute_query(sforce_session, soql)
      render :json => response_json(soql, query_result), :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(soql, query_result)
    {:soql => soql, :columns => query_result.first.keys, :rows => query_result.each{ |hash| hash.values}}
  end

end
