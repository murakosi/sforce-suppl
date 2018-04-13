require 'exceptions'

class SoqlexecuterController < ApplicationController
  before_action :require_sign_in!
  
  protect_from_forgery :except => [:show]
  
  Exclude_key_names = ["@xsi:type", "type"]
  
  def new
  end
  
  def show
  end

  def execute
    execute_soql(params[:soql]) if params[:soql].present?
  end

  def execute_soql(soql)
    begin
      get_records(soql)
      puts "query end"
      puts Time.now
      #render :json => @records, :status => 200
      render :json => @result, :status => 200
    rescue StandardError => ex
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def get_records(soql)

    puts "query start"
    puts Time.now

    query_result = current_client().query(soql)
    
    puts "sfdc query end"
    puts Time.now

    if query_result.empty?
       raise Exceptions::NoMatchedRecordError.new("No matched records found")
    end

    records = query_result.records.map{ |record| record.to_h }
                                  .map{ |hash| 
                                         hash.reject{ |k,v| Exclude_key_names.include?(k.to_s)}
                                             .reject{ |k,v| k.to_s == "id" && v.nil?}
                                  }

    @result = {:soql => soql, :columns => records.first.keys, :rows => records.each{ |hash| hash.values}}
  end

end
