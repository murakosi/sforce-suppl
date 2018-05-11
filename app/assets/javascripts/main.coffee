# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
mains = ->
  #$("#executerContent").hide()
  #$("#describeContent").hide()
  #$("#metadataContent").hide()
  #$("#describeContent").hide()

  $("#menuList").on "click", "a", (e) ->    
    toggled = ($(this).prop("id"))
    if toggled == "logoutLink"
      return
    e.stopPropagation()
    e.preventDefault()
    $("div#mainArea").prop("class", toggled)

$(document).ready(mains)
$(document).on('page:load', mains)