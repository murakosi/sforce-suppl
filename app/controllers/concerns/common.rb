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
end