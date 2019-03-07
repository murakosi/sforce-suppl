
class ToolingController < ApplicationController

  before_action :require_sign_in!
  
  protect_from_forgery :except => [:execute]
  
  def show
  end

  def execute
    execute_anonymous(params[:code])
  end

  def execute_anonymous(code)
    begin
      p result = Service::ToolingClientService.call(sforce_session).execute_anonymous("String x = 'b';system.debug(x);")
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
    "success: " + nil_or_value(result[:success]) + "<br>" +
    "compiled: " + nil_or_value(result[:compiled]) + "<br>" +
     nil_or_value(result[:line]) + ":" + nil_or_value(result[:column]) + "<br>" +
     "compile problem: " + nil_or_value(result[:compile_problem]) + "<br>" +
     "message: " + nil_or_value(result[:exception_message]) + "<br>" +
     "trace: " + nil_or_value(result[:exception_stack_trace])
  end

  def nil_or_value(value)
    if value.nil?
      ""
    else
      value.to_s
    end
  end

end
