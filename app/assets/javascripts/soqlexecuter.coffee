# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
coordinates = ->
  
  selectedTabId = 1

  #$("div#tabArea").on 'dblclick', 'ul', (e) ->
  #  alert("ok")

  $('#soqlArea .execute-soql').on 'click', (e) ->
    e.preventDefault()
    selectedTabId =  $("#soqlArea #tabArea").tabs('option', 'active') + 1
    getCoordinatesInRange()

  $(document).on 'click', 'span', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest("#soqlArea .ui-tabs").attr("id")
    tabCount = $("#soqlArea #" + tabContainerDiv).find(".ui-closable-tab").length

    if tabCount <= 1
      return

    if window.confirm("Close this tab?")
      panelId = $( this ).closest( "#soqlArea li" ).remove().attr( "aria-controls" )
      $("#soqlArea #" + panelId ).remove();
      $("#soqlArea #" + tabContainerDiv).tabs("refresh")

  $('#soqlArea #add-tab').on 'click', (e) ->
    e.preventDefault()

    new_tab_index = $("#soqlArea #tabArea ul li").length
    new_tab_id = new_tab_index + 1

    $("#soqlArea #tabArea ul").append(
      "<li class=\"noselect\"><a href=\"#tab" + new_tab_id + "\">Grid" + new_tab_id + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    $("#soqlArea #tabArea").append(
      "<div id=\"tab" + new_tab_id + "\" class=\"resultTab\">" +
      "<div id=\"soql" + new_tab_id + "\" class=\"resultSoql\"></div>" +
      "<div id=\"grid" + new_tab_id + "\" class=\"resultGrid\"></div>" +
      "</div>"
    )
    
    selectedTabId =  new_tab_id

    createGrid()
    
    $("#soqlArea #tabArea").tabs("refresh")

    $("#soqlArea #tabArea").tabs({ active: new_tab_index });

  getCoordinatesInRange = ->
    post_data = {soql: $('#soqlArea #input_soql').val()}

    jqXHR = $.ajax({
      async: true
      url: $('#soqlArea .execute-form').attr('action')
      type: $('#soqlArea .execute-form').attr('method')
      data: post_data
      dataType: 'json'
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      console.log { done: stat, data: data, xhr: xhr }
      $("#soqlArea #messageArea").empty()
      $("#soqlArea #messageArea").hide()
      createGrid(xhr.responseText)

    jqXHR.fail (xhr, stat, err) ->
      console.log { fail: stat, error: err, xhr: xhr }
      displayError(xhr.responseText)

    jqXHR.always (res1, stat, res2) ->
      console.log { always: stat, res1: res1, res2: res2 }
      #alert 'Ajax Finished!' if stat is 'success'

  displayError = (error) ->
    $("#soqlArea #messageArea").html($.parseJSON(error).error)
    $("#soqlArea #messageArea").show()

  createGrid = (result = null) ->   
    hotElement = document.querySelector("#soqlArea #grid" + selectedTabId)

    table = new Handsontable(hotElement)
    table.destroy()

    parsedResult = $.parseJSON(result)
    $("#soqlArea #soql" + selectedTabId).html(get_executed_soql(parsedResult))
    header = get_columns(parsedResult)
    records = get_rows(parsedResult)
    columns_option = get_columns_option(parsedResult)

    hotSettings = {
        data: records,
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columns_option,
        contextMenu: true,
        readOnly: true,
        startRows: 0
    }

    table = new Handsontable(hotElement, hotSettings)

  get_columns = (result) ->
    if !result?
      #[[]]
      null
    else
      result.columns

  get_rows = (result) ->
    if !result?
      null
    else
      result.rows

  get_executed_soql = (result) ->
    if !result?
      null
    else
      result.soql

  get_columns_option = (result) ->
    if !result?
      [[]]
    else
      null

  $("#soqlArea #tabArea").tabs()

  createGrid()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)