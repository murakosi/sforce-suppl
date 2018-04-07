class DescriberController < ApplicationController
  before_action :require_sign_in!

  protect_from_forgery :except => [:execute]

  def show
  end

  def execute
    @input_error = String.new

    method = params[:method].to_sym
    args = params[:args]

    if method.empty? || args.empty?
      @input_error = "input error"  
      render "show"
      return
    end
    method = "describe_global"
    begin
      #tmp = current_client.call_soap_api(method, {:sObjectType => "procure__c"})
      tmp = current_client.list_sobjects
      puts "ok"
      if tmp.kind_of?(Array)
          @result = {:method => method, :columns => ["Name"], :rows => tmp.map{|v| {"name" => v}}} 
      elsif tmp.kind_of?(Soapforce::Result)
        t2 = tmp[:fields]
        @result = {:method => method, :columns => t2.first.keys, :rows => t2.each{ |hash| hash.values}}
      else
        raise StandardError.new("error:" + tmp.to_s)
      end
      render :json => @result, :status => 200
    rescue StandardError => ex
      puts "error"
      puts ex.message
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def doit
        val = params[:input_soql].to_i

    if val == 1
      lt = current_client.describe('procure__c')
      @result = lt.map{|h| h.to_s}
    elsif val == 2
      @result = current_client.list_sobjects
    elsif val == 3
      @result = current_client.field_list('procure__c')
    else
      lt = current_client.call_soap_api(params[:method], params[:args])
      @result = lt.map{|h| h.to_s}
    end

    render "show"
  end
end
