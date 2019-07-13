coordinates = ->
  
  selectedTabId = 0
  currentTabIndex = 0
  selectedCellOnCreateGrid = null
  grids = {}
  sObjects = {}

  defaultDataType = ""
  defaultContentType = null

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
    
  executeSoql = (params) ->
    if $.isAjaxBusy()
      return false
      
    if params
      soql = params.soql_info.soql
      tooling = params.soql_info.tooling
      queryAll = params.soql_info.query_all
      tabId = params.soql_info.tab_id
    else
      soql = $('#soqlArea #input_soql').val()
      tooling = $('#soqlArea #useTooling').is(':checked')
      queryAll = $('#soqlArea #queryAll').is(':checked')
      tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId");
    
    
    if soql == null || soql == 'undefined' || soql == ""
      return false
      
    hideMessageArea()
    
    val = {soql: soql, tooling: tooling, query_all: queryAll, tab_id: tabId}
    action = $('#soqlArea .execute-form').attr('action')
    method = $('#soqlArea .execute-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)

    if params && params.afterCrud
      callbacks = $.getAjaxCallbacks(processQuerySuccessAfterCrud, displayError, null)
    else
      callbacks = $.getAjaxCallbacks(processQuerySuccess, displayError, null)

    $.executeAjax(options, callbacks)
  
  processQuerySuccess = (json) ->
    displayQueryResult(json)

  processQuerySuccessAfterCrud = (json) ->
    displayQueryResult(json)
    endCrud()

  displayQueryResult = (json) ->
    selectedTabId = json.soql_info.tab_id
    $("#soqlArea #soql" + selectedTabId).html(json.soql_info.timestamp + json.soql_info.soql)
    $("#soqlArea #tab" + selectedTabId).attr("soql", json.soql_info.soql)
    elementId = "#soqlArea #grid" + selectedTabId

    sObjects[elementId] = {
                            rows: json.records.initial_rows, 
                            columns: json.records.columns,
                            editions:{},
                            sobject_type: json.sobject,
                            soql_info: json.soql_info,
                            idColumnIndex: json.records.id_column_index,
                            editable: if json.records.id_column_index == null then false else true
                          }


    createGrid(elementId, json.records)

  #------------------------------------------------
  # Crud
  #------------------------------------------------
  executeCrud = (options) ->
    callbacks = $.getAjaxCallbacks(processCrudSuccess, processCrudError, null)
    beginCrud()
    $.executeAjax(options, callbacks)  

  beginCrud = () ->
    $("#overlay").show()
    
  endCrud = () ->
    $("#overlay").hide()
    
  processCrudSuccess = (json) ->
    if json.done
      executeSoql({soql_info:json.soql_info, afterCrud: true})
    else
      endCrud()
   
  processCrudError = (json) ->
    displayError(json)
    endCrud()

  #------------------------------------------------
  # Update
  #------------------------------------------------
  $('#soqlArea #saveBtn').on 'click', (e) ->
    e.preventDefault()
    executeUpdate()
    
  executeUpdate = () ->
    if $.isAjaxBusy()
      return false
    
    elementId = getActiveGridElementId()
    sobject = sObjects[elementId]

    if !sobject.editable || $.isEmptyObject(sobject.editions)
      return false

    hideMessageArea()

    val = {soql_info:sobject.soql_info, sobject: sobject.sobject_type, records: JSON.stringify(sobject.editions)}
    action = "/update"
    method = "post"
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    executeCrud(options)
    
  #------------------------------------------------
  # Delete
  #------------------------------------------------
  $('#soqlArea #deleteBtn').on 'click', (e) ->
    e.preventDefault()
    executeDelete()
    
  executeDelete = () ->
    if $.isAjaxBusy()
      return false
    
    elementId = getActiveGridElementId()
    sobject = sObjects[elementId]

    if !sobject.editable
      return false

    hot = grids[elementId]
    selectedCells = hot.getSelected()

    if selectedCells.length <= 0
      return false
    
    hideMessageArea()

    ids = {}
    for cells in selectedCells
      id = hot.getDataAtCell(cells[0], sobject.idColumnIndex)
      ids[id] = null

    val = {soql_info:sobject.soql_info, ids: Object.keys(ids)}
    action = "/delete"
    method = "post"
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    executeCrud(options)
    
  #------------------------------------------------
  # Undelete
  #------------------------------------------------
  $('#soqlArea #undeleteBtn').on 'click', (e) ->
    e.preventDefault()
    executeUndelete()
    
  executeUndelete = () ->
    if $.isAjaxBusy()
      return false   
    
    elementId = getActiveGridElementId()
    sobject = sObjects[elementId]

    if !sobject.editable
      return false

    hot = grids[elementId]
    selectedCells = hot.getSelected()
    
    if selectedCells.length <= 0
      return false
    
    hideMessageArea()

    ids = {}
    for cells in selectedCells
      id = hot.getDataAtCell(cells[0], sobject.idColumnIndex)
      ids[id] = null

    val = {soql_info:sobject.soql_info, ids: Object.keys(ids)}
    action = "/undelete"
    method = "post"
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    executeCrud(options)

  #------------------------------------------------
  # Edit on grid
  #------------------------------------------------    
  detectAfterEditOnGrid = (source, changes) ->

    if changes != 'edit' && !changes.startsWith('UndoRedo')
      return

    rowIndex = source[0][0]
    columnIndex = source[0][1]
    oldValue = source[0][2]
    newValue = source[0][3]

    if oldValue == newValue
      return

    isRestored = false
    
    tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#soqlArea #grid" + tabId
    
    hot = grids[elementId]
    fieldName = sObjects[elementId].columns[columnIndex]
    idColumnIndex = sObjects[elementId].idColumnIndex    
    id = hot.getDataAtCell(rowIndex, idColumnIndex)

    if sObjects[elementId].editions[id]
      if newValue == sObjects[elementId].rows[id][columnIndex]
        delete sObjects[elementId].editions[id][fieldName]
        if Object.keys(sObjects[elementId].editions[id]).length <= 0
          delete sObjects[elementId].editions[id]
        isRestored = true
      else
        sObjects[elementId].editions[id][fieldName] = newValue
    else
      sObjects[elementId].editions[id] = {}
      sObjects[elementId].editions[id][fieldName] = newValue
    
    if isRestored
      hot.removeCellMeta(rowIndex, columnIndex, 'className');
    else
      hot.setCellMeta(rowIndex, columnIndex, 'className', 'changed-cell-border');

    hot.render()

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
      executeSoql({soql_info:sObjects[elementId].soql_info, afterCrud: false})   
    
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  $("#soqlTabs").on "dblclick", (e) ->
    if e.target != this
      e.preventDefault()
      e.stopPropagation() 
      return
    
    createTab()

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
    height = if json then 500 else 0

    hotSettings = {
        data: records,
        height: height,
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
        #colWidths: (i) -> setColWidth(i),
        outsideClickDeselects: false,
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

  onCellClick = (event, coords, td) ->
    selectedCellOnCreateGrid = coords

  onTabSelect = (event, ui) ->
    $("#spaceArea").trigger('click')
      
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
  $("#soqlArea #tabArea").tabs(
    {
      select: (event, ui) -> onTabSelect(event, ui)
    }
  )
  createTab()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
