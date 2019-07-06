coordinates = ->
  
  selectedTabId = 0
  currentTabIndex = 0
  selectedCellOnCreateGrid = null
  grids = {}
  sObjects = {}

  jqXHR = null
  defaultDataType = ""
  defaultContentType = null

  getAjaxOptions = (action, method, data, datatype) ->
    {
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }

  #------------------------------------------------
  # Shortcut keys
  #------------------------------------------------
  $(window).on 'keydown', (e) ->
    if e.ctrlKey && (e.key == 'r' || e.keyCode == 13)
      e.preventDefault()
      if e.target.id == "input_soql"        
        executeSoql()
  
  #------------------------------------------------
  # Execute SOQL
  #------------------------------------------------
  $('#soqlArea .execute-soql').on 'click', (e) ->
    e.preventDefault()
    executeSoql()
    
  executeSoql = (soql_info) ->
    if jqXHR
      return false
      
    if soql_info
      soql = soql_info.soql
      tooling = soql_info.tooling
    else
      soql = $('#soqlArea #input_soql').val()
      tooling = $('#soqlArea #useTooling').is(':checked')
      
    if soql == null || soql == 'undefined'
      return false
      
    hideMessageArea()
    
    selectedTabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId");
    
    val = {soql: soql, tooling: tooling}
    action = $('#soqlArea .execute-form').attr('action')
    method = $('#soqlArea .execute-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)
  
  processSuccessResult = (json) ->
    $("#soqlArea #soql" + selectedTabId).html(json.soql_info.timestamp + json.soql_info.soql)
    $("#soqlArea #tab" + selectedTabId).attr("soql", json.soql_info.soql)
    elementId = "#soqlArea #grid" + selectedTabId

    sObjects[elementId] = {
                            rows: json.records.initial_rows, 
                            columns: json.records.columns,
                            editions:{},
                            sobject_type: json.sobject,
                            soql_info: json.soql_info
                          }


    createGrid(elementId, json.records)
  
  #------------------------------------------------
  # CSV Download
  #------------------------------------------------
  $('#soqlArea #exportBtn').on 'click', (e) ->
    hotElement = getActiveGrid()
    hotElement.getPlugin('exportFile').downloadFile('csv', {
      bom: false,
      columnDelimiter: ',',
      columnHeaders: true,
      exportHiddenColumns: true,
      exportHiddenRows: true,
      fileExtension: 'csv',
      filename: 'soql_result',
      mimeType: 'text/csv',
      rowDelimiter: '\r\n',
      rowHeaders: false
    })

  #------------------------------------------------
  # Rerun SOQL
  #------------------------------------------------
  $('#soqlArea #rerunBtn').on 'click', (e) ->
    e.preventDefault()
    
    elementId = getActiveGridElementId()
    
    if sObjects[elementId]      
      executeSoql(sObjects[elementId].soql_info)   

  $("#soqlTabs").on "dblclick", (e) ->
    if e.target != this
      console.log(e.target)
      e.preventDefault()
      e.stopPropagation() 
      return
    
    createTab()
    
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  #$(document).on 'click', 'span', (e) ->
  $(document).on 'click', '.ui-closable-tab', (e) ->
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
    createTab()
  
  createTab = () ->
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

    #createGrid("#soqlArea #grid" + newTabId)

  #--
  # Grid
  #--
  $("#clearGrid").on "click", (e) ->
    grid = grids["#soqlArea #createGrid"]
    grid.clear()

  $("#addRow").on "click", (e) ->
    grid = getActiveGrid()
    if !selectedCellOnCreateGrid? || selectedCellOnCreateGrid.row < 0
      return false
    else
      grid.alter('insert_row', selectedCellOnCreateGrid.row + 1, 1)
      grid.selectCell(selectedCellOnCreateGrid.row, selectedCellOnCreateGrid.col)

  $("#removeRow").on "click", (e) ->
    grid = getActiveGrid()
    if !selectedCellOnCreateGrid? || selectedCellOnCreateGrid.row < 0
      return false
    else
      grid.alter('remove_row', selectedCellOnCreateGrid.row, 1)
      grid.selectCell(getValidRowAfterRemove(grid), selectedCellOnCreateGrid.col)

  getValidRowAfterRemove = (grid) ->
    lastRow = grid.countVisibleRows() - 1
    if selectedCellOnCreateGrid.row > lastRow
      selectedCellOnCreateGrid.row = lastRow
    else
      selectedCellOnCreateGrid.row

  getActiveGridElementId = () ->
    tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    "#soqlArea #grid" + tabId
    
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
    minRow = getMinRow(json)

    hotSettings = {
        data: records,
        height: 500,
        #stretchH: 'all',
        autoWrapRow: true,
        allowRemoveColumn: false,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columnsOption,
        startRows: 0,
        minRows: minRow,
        minSpareRows: 0,
        minSpareCols: 0,
        fillHandle: {autoInsertRow: false},
        #fragmentSelection: true,
        columnSorting: true,
        colWidths: (i) -> setColWidth(i),
        licenseKey: 'non-commercial-and-evaluation',
        beforeColumnSort: (currentConfig, newConfig) -> onBeforeSort(currentConfig, newConfig),
        afterChange: (source, changes) -> detectAfterEditOnGrid(source, changes),
        afterOnCellMouseDown: (event, coords, td) -> onCellClick(event, coords, td)
    }

    hot = new Handsontable(hotElement, hotSettings)
    hot.updateSettings afterColumnSort: ->
      hot.render()

    grids[elementId] = hot

  setColWidth = (i) ->
    if i == 0
      30
    else
      200
  
  onBeforeSort = (currentConfig, newConfig) ->
    config = null
    if currentConfig.length > 0
      config = currentConfig
    else
      config = newConfig

    console.log(config)
    if config[0].column == 0
      return false

    console.log(currentConfig)
    console.log(newConfig)
    console.log(newConfig[0].column)
  
  getColumns = (json) ->
    if !json
      null
    else
      json.columns

  getRows = (json) ->
    if !json
      null
    else
      json.rows

  getColumnsOption = (json) ->
    if !json
      [[]]
    else if json.column_options
      json.column_options
    else 
      null

  getMinRow = (json) ->
    if json && json.min_row
      json.min_row
    else
      0

  detectAfterEditOnGrid = (source, changes) ->

    if changes != 'edit' && !changes.startsWith('UndoRedo')
      return

    console.log(source)

    rowIndex = source[0][0]
    columnIndex = source[0][1]
    oldValue = source[0][2]
    newValue = source[0][3]
    
    if columnIndex == 0
      return
    
    if oldValue == newValue
      return

    #if checked
    #    selectedRecords[rowIndex] = grids["#metadataArea #grid"].getDataAtRow(rowIndex)
    #else
    #  delete selectedRecords[rowIndex]

    tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#soqlArea #grid" + tabId
    fieldName = sObjects[elementId].columns[columnIndex]
    
    isRestored = false
    
    if sObjects[elementId].editions[rowIndex]
      if newValue == sObjects[elementId].rows[rowIndex][columnIndex]
        delete sObjects[elementId].editions[rowIndex][fieldName]
        isRestored = true
      else
        sObjects[elementId].editions[rowIndex][fieldName] = newValue
    else
      sObjects[elementId].editions[rowIndex] = {}
      sObjects[elementId].editions[rowIndex][fieldName] = newValue

    hot = grids[elementId]
    if isRestored
      hot.removeCellMeta(rowIndex, columnIndex, 'className');
      console.log("rem")
      #hot.setCellMeta(rowIndex, columnIndex, 'className', '');
    else
      hot.setCellMeta(rowIndex, columnIndex, 'className', 'changed-cell-border');
      console.log("set")
    hot.render()
    #console.log(sObjects[elementId].editions[rowIndex])
    

  onCellClick = (event, coords, td) ->
    selectedCellOnCreateGrid = coords
      
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
  #selectedTabId = 1
  #createGrid("#soqlArea #grid" + selectedTabId)

  $("#soqlArea #tabArea").tabs()
  createTab()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
