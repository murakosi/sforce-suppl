module ApplicationHelper
  def javascript(*files)
    #content_for(:head) { javascript_include_tag(*files ,"data-turbolinks-eval" => false) }
    content_for(:head) { javascript_include_tag(*files) }
  end
end
