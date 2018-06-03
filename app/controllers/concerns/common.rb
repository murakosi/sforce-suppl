module Common
  def ajax_redirect_to(redirect_uri)
    { js: "window.location.replace('#{redirect_uri}');", :status => 400 }
  end

  def safe_encode(target)
    target.encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def print_error(exception)
    Rails.backtrace_cleaner.clean(ex.backtrace)
  end
end