
class ToolingController < ApplicationController

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:execute]
  
  Time_format = "%Y/%m/%d %H:%M:%S"

  def show
  end

  def execute
    execute_anonymous(params[:code])
  end

  def execute_anonymous(code)
    begin
      p result = Service::ToolingClientService.call(sforce_session).execute_anonymous(code)
      raise_if_error(result)
      render :json => response_json(result), :status => 200
    rescue StandardError => ex
      print_error(ex)
      render :json => {:error => ex.message}, :status => 400
    end
  end

  def response_json(result)
    {:result => anonymous_result(result), :columns => [1], :rows => [[]]}
  end

  def anonymous_result(result)
    "@" + Time.now.strftime(Time_format) + "<br>"
    "success: " + result[:success].to_s + "<br>" +
    "compiled: " + result[:compiled].to_s
  end

  def raise_if_error(result)
    if result[:exception_message].present?
      msg = result[:exception_message] + "<br>" + result[:exception_stack_trace]
      raise StandardError.new(msg)
    elsif result[:compile_problem].present?
      raise StandardError.new(result[:compile_problem])
    end
  end

end
