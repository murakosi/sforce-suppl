
class SoqlexecuterController < ApplicationController
  include Soql::QueryExecuter
  before_action :require_sign_in!
  
  protect_from_forgery :except => [:execute]
  
  Exclude_key_names = ["@xsi:type", "type"]
  
  def show
  end

  def execute
    execute_soql(params[:soql]) if params[:soql].present?
  end

  def execute_soql(soql)
    begin
      #get_records(soql)
      #query_result = Soql:QueryExecuter.execute(soql)
      query_result = execute_query(sforce_session, soql)
      render :json => response_json(soql, query_result), :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(soql, query_result)
    {:soql => soql, :columns => query_result.first.keys, :rows => query_result.each{ |hash| hash.values}}
  end

  def get_records(soql)
    query_result = current_client().query(soql)

    if query_result.empty?
       raise StandardError.new("No matched records found")
    end

    records = query_result.records.map{ |record| record.to_h }
                                  .map{ |hash| 
                                         hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                  }

    @result = {:soql => soql, :columns => records.first.keys, :rows => records.each{ |hash| hash.values}}
  end

end
