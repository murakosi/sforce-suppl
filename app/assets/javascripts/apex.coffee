coordinates = ->
  
  selectedTabId = 1
  currentTabIndex = 1
  grids = {}
  logNames = {}
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
  # CSV Download
  #------------------------------------------------
  $('#apexArea #download-log').on 'click', (e) ->
    tabId = $("#apexArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#apexArea #grid" + tabId
    hotElement =grids[elementId]
    hotElement.getPlugin('exportFile').downloadFile('csv', {
      bom: false,
      columnDelimiter: ',',
      columnHeaders: true,
      exportHiddenColumns: true,
      exportHiddenRows: true,
      fileExtension: 'csv',
      filename: logNames[elementId],
      mimeType: 'text/csv',
      rowDelimiter: '\r\n',
      rowHeaders: true
    })
  
  #------------------------------------------------
  # Execute Anonymous
  #------------------------------------------------
  $('#apexArea .execute-anonymous').on 'click', (e) ->
    if $.isAjaxBusy()
      e.preventDefault()
      return false

    e.preventDefault()
    hideMessageArea()
    executeAnonymous()
    
  executeAnonymous = () ->    

    selectedTabId = $("#apexArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    val = {code: $('#apexArea #code').val()}
    action = $('#apexArea .execute-form').attr('action')
    method = $('#apexArea .execute-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)
  
  processSuccessResult = (json) ->
    elementId = "#apexArea #grid" + selectedTabId
    logNames[elementId] = json.log_name    
    $("#apexArea #soql" + selectedTabId).html(json.log_name)    
    createGrid(elementId, json)
    
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  $(document).on 'click', 'span', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest("#apexArea .ui-tabs").attr("id")
    tabCount = $("#apexArea #" + tabContainerDiv).find(".ui-closable-tab").length

    if tabCount <= 1
      return

    if window.confirm("Close this tab?")
      panelId = $(this).closest("#apexArea li").remove().attr("aria-controls")
      $("#apexArea #" + panelId ).remove();
      $("#apexArea #" + tabContainerDiv).tabs("refresh")

  $('#apexArea #add-tab').on 'click', (e) ->
    e.preventDefault()
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#apexArea #tabArea ul").append(
      "<li class=\"noselect\"><a href=\"#tab" + newTabId + "\">Grid" + newTabId + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    $("#apexArea #tabArea").append(
      "<div id=\"tab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\">" +
      "<div id=\"soql" + newTabId + "\" class=\"resultSoql\" tabId=\"" + newTabId + "\"></div>" +
      "<div id=\"grid" + newTabId + "\" class=\"resultGrid\" tabId=\"" + newTabId + "\"></div>" +
      "</div>"
    )
    
    createGrid("#apexArea #grid" + newTabId)
    
    $("#apexArea #tabArea").tabs("refresh")
    
    newTabIndex = $("#apexArea #tabArea ul li").length - 1
    selectedTabId = newTabIndex
    $("#apexArea #tabArea").tabs({ active: newTabIndex });
      
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
    $("#apexArea #messageArea").html(json.error)
    $("#apexArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#apexArea #messageArea").empty()
    $("#apexArea #messageArea").hide()
    
  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  selectedTabId = 1
  createGrid("#apexArea #grid" + selectedTabId)

  $("#apexArea #tabArea").tabs()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)