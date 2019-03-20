###
coordinates = ->
  
  selectedTabId = 1
  currentTabIndex = 1
  grids = {}
  jqXHR = null
  defaultDataType = ""
  defaultContentType = null

  #------------------------------------------------
  # Shortcut keys
  #------------------------------------------------
  $(window).on 'keydown', (e) ->
    if e.ctrlKey && e.key == 'r'
      e.preventDefault()
      executeAnonymous()
  
  #------------------------------------------------
  # Execute SOQL
  #------------------------------------------------
  $('#toolingArea .execute-anonymous').on 'click', (e) ->
    if $.isAjaxBusy()
      e.preventDefault()
      return false

    e.preventDefault()
    hideMessageArea()
    executeAnonymous()
    
  executeAnonymous = () ->    

    selectedTabId = $("#toolingArea #tabArea .ui-tabs-panel:visible").attr("tabId");
    val = {code: $('#toolingArea #code').val()}
    action = $('#toolingArea .execute-form').attr('action')
    method = $('#toolingArea .execute-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)
  
  processSuccessResult = (json) ->
    $("#toolingArea #soql" + selectedTabId).html(getExecuteResult(json))
    elementId = "#toolingArea #grid" + selectedTabId
    createGrid(elementId, json)
    
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  $(document).on 'click', 'span', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest("#toolingArea .ui-tabs").attr("id")
    tabCount = $("#toolingArea #" + tabContainerDiv).find(".ui-closable-tab").length

    if tabCount <= 1
      return

    if window.confirm("Close this tab?")
      panelId = $(this).closest("#toolingArea li").remove().attr("aria-controls")
      $("#toolingArea #" + panelId ).remove();
      $("#toolingArea #" + tabContainerDiv).tabs("refresh")

  $('#toolingArea #add-tab').on 'click', (e) ->
    e.preventDefault()
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#toolingArea #tabArea ul").append(
      "<li class=\"noselect\"><a href=\"#tab" + newTabId + "\">Grid" + newTabId + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    $("#toolingArea #tabArea").append(
      "<div id=\"tab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\">" +
      "<div id=\"soql" + newTabId + "\" class=\"resultSoql\" tabId=\"" + newTabId + "\"></div>" +
      "<div id=\"grid" + newTabId + "\" class=\"resultGrid\" tabId=\"" + newTabId + "\"></div>" +
      "</div>"
    )
    
    createGrid("#toolingArea #grid" + newTabId)
    
    $("#toolingArea #tabArea").tabs("refresh")
    
    newTabIndex = $("#toolingArea #tabArea ul li").length - 1
    selectedTabId = newTabIndex
    $("#toolingArea #tabArea").tabs({ active: newTabIndex });
      
  #------------------------------------------------
  # Create grid
  #------------------------------------------------
  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    if grids[elementId]
      table = grids[elementId]
      table.destroy()

    header = getColumns(json)
    records = getRows(json)
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
        startRows: 0,
        licenseKey: 'non-commercial-and-evaluation'
    }

    grids[elementId] = new Handsontable(hotElement, hotSettings)

  getColumns = (json) ->
    if !json?
      null
    else
      json.columns
  
  getRows = (json) ->
    if !json?
      null
    else
      json.rows

  getExecuteResult = (json) ->
    if !json?
      null
    else
      json.result

  getColumnsOption = (json) ->
    if !json?
      [[]]
    else
      null
      
  #------------------------------------------------
  # message
  #------------------------------------------------
  displayError = (json) ->
    $("#toolingArea #messageArea").html(json.error)
    $("#toolingArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#toolingArea #messageArea").empty()
    $("#toolingArea #messageArea").hide()
    
  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  selectedTabId = 1
  createGrid("#toolingArea #grid" + selectedTabId)

  $("#toolingArea #tabArea").tabs()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
###