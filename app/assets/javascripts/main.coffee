
mains = ->

  selectedAnchor = null
  jqXHR = null
  loadedPartials = {}
  targetDiv = null
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
    clickedAnchor = ($(this).prop("id"))

    if selectedAnchor == clickedAnchor
      e.preventDefault
      return false
    
    if clickedAnchor == "logoutLink"
      return

    if jqXHR
      e.preventDefault
      return false

    e.stopPropagation()
    selectedAnchor = clickedAnchor
    targetDiv = $(this).attr("loadTarget")
    anchorObject = this

    method = $(this).attr('method')
    action = $(this).attr('action')

    if loadedPartials[selectedAnchor] || action == ""
      changeDisplayDiv(selectedAnchor)      
      return
    
    options = getAjaxOptions(action, method, null, defaultDetatype)

    $.get action, (result) ->
      loadPartials(result)
  
  loadPartials = (json) ->
    loadedPartials[selectedAnchor] = true
    $("div" + json.target).html(json.content)
    changeDisplayDiv(selectedAnchor)
    if json.status != 200
      createErrorDiv(json.error)

  changeAnchorClass = (target) ->
    $(".menus").not(target).removeClass("displayed")

    if $(target).hasClass("displayed")
      $(target).removeClass("displayed")
    else
      $(target).addClass("displayed")

  changeDisplayDiv = (target) ->
    if $(anchorObject).hasClass("nochange")
      return
    
    changeAnchorClass(anchorObject)
    $("div#mainArea").prop("class", target)
    $('.selectlist').select2({
      dropdownAutoWidth : true,
      width: 'resolve',
      containerCssClass: ':all:'
      })

  createErrorDiv = (message) ->
    html = "<div style='text-align:center; white-space: pre; color:red; font-weight:bold;'>" + message  + "</div>"
    $(targetDiv).html(html)

  autoClickAnchor = (target) ->
    $("#" + target)[0].click()

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