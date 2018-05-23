
mains = ->

  selectedAnchor = null
  jqXHR = null
  loadedPartials = {}
  defaultDetatype = ""
  anchorObject = null

  getAjaxOptions = (action, method, data, datatype) ->
    {
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype,
    }

  $("#menuList").on "click", "a", (e) ->
    selectedAnchor = ($(this).prop("id"))

    if selectedAnchor == "logoutLink"
      return

    if jqXHR
      e.preventDefault
      return false;

    e.stopPropagation()
    #changeAnchorClass(this)
    anchorObject = this

    method = $(this).attr('method')
    action = $(this).attr('loadTarget')

    if loadedPartials[selectedAnchor] || action == ""
      changeDisplayDiv(selectedAnchor)
      
      return
    
    options = getAjaxOptions(action, method, null, defaultDetatype)
    #executeSyncAjax(options, loadPartials)
    $.get action, (result) ->
      console.log(result)
      loadPartials(result)
  
  loadPartials = (result) ->
    loadedPartials[selectedAnchor] = true
    json = result#$.parseJSON(result)
    $("div" + json.target).html(json.content)
    changeDisplayDiv(selectedAnchor)

  changeAnchorClass = (target) ->
    $(".menus").not(target).removeClass("displayed");

    if $(target).hasClass("displayed")
      $(target).removeClass("displayed");
    else
      $(target).addClass("displayed");

  changeDisplayDiv = (target) ->
    changeAnchorClass(anchorObject)
    $("div#mainArea").prop("class", target)

  autoClickAnchor = (target) ->
    $("#" + target)[0].click();

  executeSyncAjax = (options, callback) ->
    if jqXHR
      return

    $.ajax({
      async: false,
      url: options.action
      type: options.method
      data: options.data
      dataType: options.datatype
      cache: false
    }).done (data, stat, xhr) ->
      console.log { done: stat, data: data, xhr: xhr }
      callback(data)

  executeAjax = (options, callback) ->

    if jqXHR
      return

    jqXHR = $.ajax({
      url: options.action
      type: options.method
      data: options.data
      dataType: options.datatype
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      jqXHR = null
      console.log { done: stat, data: data, xhr: xhr }
      callback(data)

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      alert(err)

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  options = getAjaxOptions("main", "POST", "describe", "TEXT")
  executeAjax(options, autoClickAnchor)

$(document).ready(mains)
$(document).on('page:load', mains)