
class ApexController < ApplicationController

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
        result = Service::ApexClientService.call(sforce_session).execute_anonymous(code)
        raise_if_error(result[:anonymous_result])
        render :json => response_json(result[:debug_log]), :status => 200
    rescue StandardError => ex
        print_error(ex)
        render :json => {:error => ex.message}, :status => 400
    end
    end

    def response_json(debug_log)
        {
            :log_name => "excecuteAnonymous @" + Time.now.strftime(Time_format),
            :columns => [:details],
            :rows => debug_log.split("\n").map{|str| [str]}
        }
    end

    def anonymous_result(result)
        "@" + Time.now.strftime(Time_format)
    end

    def raise_if_error(result)
        if !result[:success]
            msg = result[:exception_message] + "<br>" + result[:exception_stack_trace]
            raise StandardError.new(msg)
        elsif !result[:compiled]
            raise StandardError.new(result[:compile_problem])
        end
    end

end
