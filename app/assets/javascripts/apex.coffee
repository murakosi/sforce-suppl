coordinates = ->
  
  selectedTabId = 1
  currentTabIndex = 1
  grids = {}
  logNames = {}
  jqXHR = null
  defaultDataType = ""
  defaultContentType = null
  eventColumnIndex = 1
  USER_DEBUG = "USER_DEBUG"

  #------------------------------------------------
  # Shortcut keys
  #------------------------------------------------
  $(window).on 'keydown', (e) ->
    if e.ctrlKey && (e.key == 'r' || e.keyCode == 13)
      e.preventDefault()
      if e.target.id == "apex_code"
        executeAnonymous()

    if e.keyCode is 9
      e.preventDefault()
      elem = e.target
      start = elem.selectionStart
      end = elem.selectionEnd
      value = elem.value
      elem.value = "#{value.substring 0, start}\t#{value.substring end}"
      elem.selectionStart = elem.selectionEnd = start + 1
      false

  #------------------------------------------------
  # Debug options
  #------------------------------------------------  
  $('#apexArea #debug-opt-btn').on 'click', (e) ->
    e.preventDefault()
    area = $('#debugOptions')
    if area.css('display') == 'none'
      area.css('display', 'block')
    else
      area.css('display', 'none')

  #------------------------------------------------
  # CSV Download
  #------------------------------------------------
  $('#apexArea #download-log').on 'click', (e) ->
    tabId = $("#apexArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#apexArea #grid" + tabId
    if logNames[elementId]
      hotElement =grids[elementId]
      hotElement.getPlugin('exportFile').downloadFile('csv', {
        bom: true,
        columnDelimiter: ',',
        columnHeaders: true,
        exportHiddenColumns: false,
        exportHiddenRows: false,
        fileExtension: 'csv',
        filename: logNames[elementId],
        mimeType: 'text/csv',
        rowDelimiter: '\r\n',
        rowHeaders: true
      })

  #------------------------------------------------
  # Filter debug only
  #------------------------------------------------
  $("#apexArea").on "click", "input.debugOnly", ->
    if $(this).prop("checked")
      filterLog()
    else
      clearFilter()

  filterLog = () ->
    tabId = $("#apexArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#apexArea #grid" + tabId
    hotElement =grids[elementId]    
    filtersPlugin = hotElement.getPlugin('filters');
    filtersPlugin.removeConditions(eventColumnIndex);
    filtersPlugin.addCondition(eventColumnIndex, 'eq', [USER_DEBUG]);
    filtersPlugin.filter()
    hotElement.render()


  clearFilter = () ->
    tabId = $("#apexArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#apexArea #grid" + tabId
    hotElement =grids[elementId]
    filtersPlugin = hotElement.getPlugin('filters');
    filtersPlugin.clearConditions();
    filtersPlugin.filter()
    hotElement.render()

  #------------------------------------------------
  # Execute Anonymous
  #------------------------------------------------
  $('#apexArea .execute-anonymous').on 'click', (e) ->
    if $.isAjaxBusy()
      e.preventDefault()
      return false

    e.preventDefault()
    executeAnonymous()
    
  executeAnonymous = () ->    

    hideMessageArea()
    selectedTabId = $("#apexArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    debugOptions = {}
    $('#debugOptions option:selected').each () ->
      category = $(this).parent().attr("id")
      level = $(this).val()
      debugOptions[category] = level
      
    val = {code: $('#apexArea #apex_code').val(), debug_options: debugOptions}
    action = $('#apexArea .execute-form').attr('action')
    method = $('#apexArea .execute-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)
  
  processSuccessResult = (json) ->
    elementId = "#apexArea #grid" + selectedTabId
    logNames[elementId] = json.log_name    
    $("#apexArea #soql" + selectedTabId).html(getLogResult(json))
    createGrid(elementId, json)

  getLogResult = (json) ->
    json.log_name + #<label><input type="checkbox" /> Label text</label>
    '&nbsp;&nbsp;<label><input type="checkbox" class="debugOnly"/> Debug only</label>'
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  $(document).on 'click', 'span', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest("#apexArea .ui-tabs").attr("id")
    tabCount = $("#apexArea #" + tabContainerDiv).find(".ui-closable-tab").length

    if tabCount <= 1
      return

    panelId = $(this).closest("#apexArea li").remove().attr("aria-controls")
    $("#apexArea #" + panelId ).remove();
    $("#apexArea #" + tabContainerDiv).tabs("refresh")

  $('#apexArea #add-tab').on 'click', (e) ->
    e.preventDefault()
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#apexArea #tabArea ul").append(
      "<li class=\"noselect\"><a href=\"#tab" + newTabId + "\">Log" + newTabId + "</a>" +
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
        height: 500,
        stretchH: 'last',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        fragmentSelection: 'cell',
        filters: true,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        trimWhitespace: false,
        licenseKey: 'non-commercial-and-evaluation'
    }

    hot = new Handsontable(hotElement, hotSettings)
    grids[elementId] = hot
    hot.render()

  getColumns = (json) ->
    if json && json.columns
      json.columns
    else
      null
  
  getRows = (json) ->
    if json && json.rows
      json.rows
    else
      null

  getExecuteResult = (json) ->
    if json && json.result
      json.result
    else
      null

  getColumnsOption = (json) ->
    if json && json.columnOptions
      json.columnOptions
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

  $("#apexArea #tabArea").tabs()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
