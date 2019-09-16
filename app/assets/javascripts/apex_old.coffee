coordinates = ->
  
  selectedTabId = 0
  currentTabIndex = 0
  grids = {}
  logNames = {}
  defaultDataType = ""
  defaultContentType = null
  eventColumnIndex = 1
  USER_DEBUG = "USER_DEBUG"

  #------------------------------------------------
  # Shortcut keys
  #------------------------------------------------
  $(window).on 'keydown', (e) ->
    if e.target.id == "apex_code"

      if e.ctrlKey && (e.key == 'r' || e.keyCode == 13)  
        executeAnonymous()
        return false

      if e.keyCode is 9
        elem = e.target
        start = elem.selectionStart
        end = elem.selectionEnd
        value = elem.value
        elem.value = "#{value.substring 0, start}\t#{value.substring end}"
        elem.selectionStart = elem.selectionEnd = start + 1
        return false
  #------------------------------------------------
  # Execute Anonymous
  #------------------------------------------------
  $('#apexArea #executeAnonymousBtm').on 'click', (e) ->
    if $.isAjaxBusy()
      return false

    if !$('#apexArea #apex_code').val()
      return false

    executeAnonymous()
    
  executeAnonymous = () ->    

    hideMessageArea()
    selectedTabId = $("#apexArea .tabArea .ui-tabs-panel:visible").attr("tabId")

    debugOptions = {}    
    $('#debugOptions option:selected').each () ->
      category = $(this).parent().attr("id")
      level = $(this).val()
      debugOptions[category] = level
      
    val = {code: $('#apexArea #apex_code').val(), debug_options: debugOptions}
    action = $('#apexArea .execute-anonymous-form').attr('action')
    method = $('#apexArea .execute-anonymous-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)
  
  processSuccessResult = (json) ->
    elementId = "#apexArea #apexGrid" + selectedTabId
    logNames[elementId] = json.log_name    
    $("#apexArea #logInfo" + selectedTabId).html(getLogResult(json))
    createGrid(elementId, json)

  getLogResult = (json) ->
    json.log_name + '&nbsp;&nbsp;<label><input type="checkbox" class="debugOnly"/>&nbsp;Debug only</label>'

  #------------------------------------------------
  # Debug options
  #------------------------------------------------  
  $('#apexArea #debugOptionBtn').on 'click', (e) ->
    if $('#debugOptions').is(":visible")
      $('#debugOptions').hide()
    else
      $('#debugOptions').show()

  #------------------------------------------------
  # CSV Download
  #------------------------------------------------
  $('#apexArea #downloadLogBtn').on 'click', (e) ->
    elementId = getActiveGridElementId()
    logName = logNames[elementId]
    if logName
      hotElement =grids[elementId]
      hotElement.getPlugin('exportFile').downloadFile('csv', {
        bom: true,
        columnDelimiter: ',',
        columnHeaders: true,
        exportHiddenColumns: false,
        exportHiddenRows: false,
        fileExtension: 'csv',
        filename: logName,
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
    elementId = getActiveGridElementId()
    hotElement = grids[elementId]    
    filtersPlugin = hotElement.getPlugin('filters');
    filtersPlugin.removeConditions(eventColumnIndex);
    filtersPlugin.addCondition(eventColumnIndex, 'eq', [USER_DEBUG]);
    filtersPlugin.filter()
    hotElement.render()


  clearFilter = () ->
    elementId = getActiveGridElementId()
    hotElement = grids[elementId]
    filtersPlugin = hotElement.getPlugin('filters');
    filtersPlugin.clearConditions();
    filtersPlugin.filter()
    hotElement.render()

  #------------------------------------------------
  # Create tab
  #------------------------------------------------
  $(document).on 'click', '#apexArea .ui-closable-tab', (e) ->
    e.preventDefault()

    if $("#apexArea .tabArea ul li").length <= 2
      return

    panelId = $(this).closest("#apexArea li").remove().attr("aria-controls")
    $("#apexArea #" + panelId ).remove();
    $("#apexArea .tabArea").tabs("refresh")

  $('#apexArea .add-tab-btn').on 'click', (e) ->
    e.preventDefault()
    createTab()
  
  createTab = () ->
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#apexArea .tabArea ul li:last").before(
      '<li class="noselect"><a href="#apexTab' + newTabId + '">Grid' + newTabId + '</a>' +
      '<span class="ui-icon ui-icon-close ui-closable-tab"></span>' +
      '</li>'
    )

    logInfoArea = '<div id="logInfo' + newTabId + '" class="resultSoql" tabId="' + newTabId + '"></div>'    
    
    $("#apexArea .tabArea").append(
      '<div id="apexTab' + newTabId + '" class="resultTab" tabId="' + newTabId + '">' +
      logInfoArea +
      '<div id="apexGrid' + newTabId + '" class="resultGrid" tabId="' + newTabId + '"></div>' +
      '</div>'
    )
    
    createGrid("#apexArea #apexGrid" + newTabId)
    
    $("#apexArea .tabArea").tabs("refresh")

    setSortableAttribute()
    
    newTabIndex = $("#apexArea .tabArea ul li").length - 2
    selectedTabId = newTabIndex
    $("#apexArea .tabArea").tabs({ active: newTabIndex});

  setSortableAttribute = () ->
    if $("#apexTabs li" ).length > 2
      $("#apexTabs").sortable("enable")
    else
      $("#apexTabs").sortable('disable')

  #------------------------------------------------
  # Active grid
  #------------------------------------------------
  getActiveTabElementId = () ->
    $("#apexArea .tabArea .ui-tabs-panel:visible").attr("tabId")

  getActiveGridElementId = () ->
    tabId = $("#apexArea .tabArea .ui-tabs-panel:visible").attr("tabId")
    "#apexArea #describeGrid" + tabId
    
  getActiveGrid = () ->
    elementId = getActiveGridElementId()
    grids[elementId]

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
    height = if json then 500 else 0

    hotSettings = {
        data: records,
        #height: height,
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
    $("#apexArea .messageArea").html(json.error)
    $("#apexArea .messageArea").show()
  
  hideMessageArea = () ->
    $("#apexArea .messageArea").empty()
    $("#apexArea .messageArea").hide()
    
  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  $("#apexArea .tabArea").tabs()
  $("#apexTabs").sortable({items: 'li:not(.add-tab-li)', delay: 150});
  createTab()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
