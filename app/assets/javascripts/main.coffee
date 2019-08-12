
mains = ->

  selectedAnchor = null
  loadedPartials = {}
  targetDiv = null
  defaultDetatype = ""
  defaultContentType = null
  anchorObject = null
  describeFault = false

  $("#menus").on "click", "a", (e) ->
    clickedAnchor = ($(this).prop("id"))

    if selectedAnchor == clickedAnchor
      e.preventDefault()
      return false

    e.preventDefault()
    e.stopPropagation()
    selectedAnchor = clickedAnchor
    targetDiv = $(this).attr("loadTarget")
    anchorObject = this

    action = $(this).attr('action')

    if loadedPartials[selectedAnchor] || action == ""
      changeDisplayDiv(selectedAnchor)      
      return
    
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

    if target == "metadata"
      targetSelect2 = "div#" + target + "Area .selectlist"
      $(targetSelect2).select2({
        dropdownAutoWidth : true,
        width: 'resolve',
        containerCssClass: ':all:'
        })
    
    $(document).trigger("displayChange", [{targetArea: target + "Area"}]);
    
  createErrorDiv = (message) ->
    html = "<div style='text-align:center; white-space: pre; color:red; font-weight:bold;'>" + message  + "</div>"
    $(targetDiv).html(html)
  

  action = "prepare"
  $.get action, (json) ->
    $("div.sobject-list").html(json.content)
    if json.status != 200
      targetDiv = "#describeContent"
      createErrorDiv(json.error)
    else
      $(".selectlist").select2({
        dropdownAutoWidth : true,
        width: 'resolve',
        containerCssClass: ':all:'
        })

$(document).ready(mains)
$(document).on('page:load', mains)
