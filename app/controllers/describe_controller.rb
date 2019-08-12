
class DescribeController < ApplicationController
    include Describe::DescribeExecuter
  
    before_action :require_sign_in!

    protect_from_forgery :except => [:change, :describe, :download]

    def show
        begin
            sobjects = get_sobject_names(sforce_session, Describe::SobjectType::Custom)
            html_content = render_to_string :partial => 'sobjectlist', :locals => {:data_source => sobjects}
            render :json => {:target => "#sobjectList", :content => html_content, :error => nil, :status => 200}
        rescue StandardError => ex
            html_content = render_to_string :partial => 'sobjectlist', :locals => {:data_source => []}
            render :json => {:target => "#sobjectList", :content => html_content, :error => ex.message, :status => 400}
        end
    end

    def change
        sobject_type = params[:object_type]

        if sobject_type == "all"
            sobjects = get_sobject_names(sforce_session, Describe::SobjectType::All)
        elsif sobject_type == "standard"
            sobjects = get_sobject_names(sforce_session, Describe::SobjectType::Standard)
        elsif sobject_type == "custom"
            sobjects = get_sobject_names(sforce_session, Describe::SobjectType::Custom)
        else
            raise StandardError.new("Invalid object type parameter")
        end  

        render :partial => 'sobjectlist', :locals => {:data_source => sobjects}
    end

    def describe
        sobject = params[:selected_sobject]

        begin
            describe_result = describe_field(sforce_session, sobject)
            formatted_result = format_field_result(sobject, describe_result[:fields])
            render :json => response_json(describe_result, formatted_result), :status => 200
        rescue StandardError => ex
            print_error(ex)
            render :json => {:error => ex.message}, :status => 400
        end
    end

    def response_json(describe_result, formatted_result)
        {
            :method => get_sobject_info(describe_result),
            :columns => formatted_result.first.keys,
            :rows => formatted_result.each{ |hash| hash.values}
        }
    end

    def get_sobject_info(describe_result)
        info = "Label：" + describe_result[:label].to_s + "\n" +
              "API Name：" + describe_result[:name].to_s + "\n" +
              "Prefix：" + describe_result[:key_prefix].to_s
    end
  
    def download
        sobject = params[:selected_sobject]

        begin
            describe_result = describe_field(sforce_session, sobject)
            formatted_result = format_field_result(sobject, describe_result[:fields])
            try_download("csv", sobject, formatted_result)
            set_download_success_cookie(response)
        rescue StandardError => ex
            print_error(ex)
            respond_download_error(ex.message)
        end
    end

    def try_download(format, sobject, result)
        if format == "csv"
            download_csv(sobject, result)
        elsif format == "excel"
            download_excel(sobject, result)
        end
    end

    def set_download_success_cookie(response)
        response.set_cookie("fileDownload", {:value => true, :path => "/"})
    end

    def respond_download_error(message)
        respond_to do |format|
            format.js {render :json => {:error => message, :status => 400}}
            format.html {render :json => {:error => message, :status => 400}}
            format.text {render :json => {:error => message, :status => 400}}
        end
    end

    def download_csv(sobject, result)
        generator = Generator::DescribeCsvGenerator.new(Encoding::SJIS, "\r\n", true)
        send_data(generator.generate(:data => result),
            :disposition => 'attachment',
            :type => 'text/csv',
            :filename => sobject + '.csv',
            :status => 200
        )
    end

    def download_excel(sobject, result)
        generator = Generator::ExcelGeneratorProxy.generator(:DescribeResult)
        send_data(generator.generate(result),
            :disposition => 'attachment',
            :type => 'application/excel',
            :filename => sobject + '.xlsx',
            :status => 200
        )
    end
end
