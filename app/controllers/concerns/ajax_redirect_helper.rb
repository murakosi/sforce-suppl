module AjaxRedirectHelper
  def ajax_redirect_to(redirect_uri)
    { js: "window.location.replace('#{redirect_uri}');", :status => 400 }
  end
end