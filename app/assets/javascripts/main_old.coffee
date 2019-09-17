
mains = ->

  selectedAnchor = null
  loadedPartials = {}
  targetDiv = null
  defaultDetatype = ""
  defaultContentType = null
  anchorObject = null

  $("#menus").on "click", "a", (e) ->
    if $("#dropdown-menu").is(":visible")
      $("#userInfoButton").trigger("click")
      
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
      targetSelect2 = "div#metadataArea .selectlist"
      $(targetSelect2).select2({
        dropdownAutoWidth : true,
        width: 'resolve',
        containerCssClass: ':all:',
        placeholder: "Select a metadata type",
        allowClear: true
        })
    
    $(document).trigger("displayChange", [{targetArea: target + "Area"}]);

  refreshSObjectLists = () ->
    $(".sobject-select-list").select2({
      dropdownAutoWidth : true,
      width: 'element',
      containerCssClass: ':all:',
      placeholder: "Select an sObject",
      allowClear: true
    })

  $("a#refreshDescribe").on "click", (e) ->
    alert("refresh")
    return false
  
  refreshSObjectLists()
      
  $("a#soqlexecuter").trigger("click");

$(document).ready(mains)
$(document).on('page:load', mains)