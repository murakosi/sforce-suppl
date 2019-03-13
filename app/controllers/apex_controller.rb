
class ApexController < ApplicationController

    before_action :require_sign_in!

    protect_from_forgery :except => [:execute]

    Time_format = "%Y/%m/%d %H:%M:%S"
    Log_split_char = "|"
    Log_split_limit = 3
    Log_headers = ["Timestamp", "Event", "Details"]

    def show
    end

    def execute
        execute_params = params.permit!.to_h
        execute_anonymous(execute_params[:code], execute_params[:debug_options])
    end

    def execute_anonymous(code, debug_options)
        begin
            debug_categories = {:debug_categories => debug_options.map{|k,v| {:category => k, :level => v} } }
            result = Service::ApexClientService.call(sforce_session.merge(debug_categories)).execute_anonymous(code)
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
            :columns => Log_headers,
            :rows => format_log(debug_log),
            :columnOptions => [{:type => "text"},{:type => "text"}, nil]
        }
    end

    def format_log(debug_log)
        logs = debug_log.split("\n").map{|str| str.split(Log_split_char, Log_split_limit)}
        logs.select{|log| log.length >= 1}.map{|log| fill_blank(log)}
    end

    def fill_blank(log)
        if log.length == 1
            ["","",log[0]]
        elsif log.length == 2
            [log[0],log[1],""]
        else
            log
        end
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
