module Common
    def ajax_redirect_to(redirect_uri)
        { js: "window.location.replace('#{redirect_uri}');", :status => 400 }
    end

    def safe_encode(target)
        target.encode("UTF-8", invalid: :replace, undef: :replace)
    end

    def print_error(exception)
        p exception.message
        p Rails.backtrace_cleaner.clean(exception.backtrace)
    end

    def set_download_success_cookie(response)
        response.set_cookie("fileDownload", {:value => true, :path => "/"})
    end

    def respond_download_error(message)
        respond_to do |format|
            format.html {render :json => {:error => message}, :status => 400}
            format.text {render :json => {:error => message}, :status => 400}
            format.js {render :json => {:error => message}, :status => 400}
        end
    end
end