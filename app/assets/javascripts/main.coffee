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
    #e.preventDefault()
    $('.menus').not(this).removeClass('displayed');
    if $(this).hasClass('displayed')
      $(this).removeClass('displayed');
    else
      $(this).addClass('displayed');
      
    $("div#mainArea").prop("class", toggled)

  changeDisplay = (d) ->
    #$("div#mainArea").prop("class", d)
    $("#" + d)[0].click();

  executeAjax = (options) ->

    if jqXHR
      return

    jqXHR = $.ajax({
      async: true
      url: "main"
      type: "POST"
      data: options
      dataType: "text"
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      jqXHR = null
      console.log { done: stat, data: data, xhr: xhr }
      changeDisplay(data)

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      alert(err)

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  executeAjax("describe")

$(document).ready(mains)
$(document).on('page:load', mains)