
mains = ->

  $("#menuList").on "click", "a", (e) ->
    toggled = ($(this).prop("id"))

    if toggled == "logoutLink"
      return

    e.stopPropagation()

    $('.menus').not(this).removeClass('displayed');

    if $(this).hasClass('displayed')
      $(this).removeClass('displayed');
    else
      $(this).addClass('displayed');

    partialPath = $(this).attr('partialPath')
    loadTarget = $(this).attr('loadTarget')
    loadPartial(toggled, loadTarget, partialPath)
  
  loadPartial = (toggleId, loadTarget, partialPath) ->
    $("div#mainArea").prop("class", toggleId)

  changeDisplay = (d) ->
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