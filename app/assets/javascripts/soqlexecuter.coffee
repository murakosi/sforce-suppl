coordinates = ->
  
  selectedTabId = 1
  currentTabIndex = 1
  grids = {}
  jqXHR = null
  defaultDataType = ""

  getAjaxOptions = (action, method, data, datatype) ->
    {
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }
    
  #------------------------------------------------
  # Execute SOQL
  #------------------------------------------------
  $('#soqlArea .execute-soql').on 'click', (e) ->
    if jqXHR
      return
    
    e.preventDefault()
    selectedTabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId");
    val = {soql: $('#soqlArea #input_soql').val()}
    action = $('#soqlArea .execute-form').attr('action')
    method = $('#soqlArea .execute-form').attr('method')
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, processSuccessResult, displayError)
  
  processSuccessResult = (json) ->
    $("#soqlArea #soql" + selectedTabId).html(getExecutedSoql(json))
    elementId = "#soqlArea #grid" + selectedTabId
    createGrid(elementId, json)
    
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  $(document).on 'click', 'span', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest("#soqlArea .ui-tabs").attr("id")
    tabCount = $("#soqlArea #" + tabContainerDiv).find(".ui-closable-tab").length

    if tabCount <= 1
      return

    if window.confirm("Close this tab?")
      panelId = $(this).closest("#soqlArea li").remove().attr("aria-controls")
      $("#soqlArea #" + panelId ).remove();
      $("#soqlArea #" + tabContainerDiv).tabs("refresh")

  $('#soqlArea #add-tab').on 'click', (e) ->
    e.preventDefault()
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#soqlArea #tabArea ul").append(
      "<li class=\"noselect\"><a href=\"#tab" + newTabId + "\">Grid" + newTabId + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    $("#soqlArea #tabArea").append(
      "<div id=\"tab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\">" +
      "<div id=\"soql" + newTabId + "\" class=\"resultSoql\" tabId=\"" + newTabId + "\"></div>" +
      "<div id=\"grid" + newTabId + "\" class=\"resultGrid\" tabId=\"" + newTabId + "\"></div>" +
      "</div>"
    )
    
    createGrid("#soqlArea #grid" + newTabId)
    
    $("#soqlArea #tabArea").tabs("refresh")
    
    newTabIndex = $("#soqlArea #tabArea ul li").length - 1
    selectedTabId = newTabIndex
    $("#soqlArea #tabArea").tabs({ active: newTabIndex });
    
  #------------------------------------------------
  # Execute ajax
  #------------------------------------------------
  executeAjax = (options, doneCallback, errorCallback, params = null) ->

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
      hideMessageArea()
      doneCallback($.parseJSON(xhr.responseText), params)

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      errorCallback($.parseJSON(xhr.responseText))

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      
  #------------------------------------------------
  # Create grid
  #------------------------------------------------
  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    if grids[elementId]
      table = grids[elementId]
      table.destroy()

    header = getColumns(json)
    records = parseSoqlResult(json)
    columnsOption = getColumnsOption(json)

    hotSettings = {
        data: records,
        height: 500;
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columnsOption,
        contextMenu: false,
        readOnly: true,
        startRows: 0
    }

    grids[elementId] = new Handsontable(hotElement, hotSettings)

  getColumns = (json) ->
    if !json?
      null
    else
      json.columns

  parseSoqlResult = (json) ->
    rawResult = getRows(json)
    
    if rawResult == null
      return null
    console.log(rawResult)
    if typeof rawResult == "object"
      value = Object.values(rawResult)
    else
      value = rawResult
    
    return value
  
  getRows = (json) ->
    if !json?
      null
    else
      json.rows

  getExecutedSoql = (json) ->
    if !json?
      null
    else
      json.soql

  getColumnsOption = (json) ->
    if !json?
      [[]]
    else
      null
      
  #------------------------------------------------
  # message
  #------------------------------------------------
  displayError = (json) ->
    $("#soqlArea #messageArea").html(json.error)
    $("#soqlArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#soqlArea #messageArea").empty()
    $("#soqlArea #messageArea").hide()
    
  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  selectedTabId = 1
  createGrid("#soqlArea #grid" + selectedTabId)

  $("#soqlArea #tabArea").tabs()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)