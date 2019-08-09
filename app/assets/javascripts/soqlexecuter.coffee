coordinates = ->
  
  currentTabIndex = 0
  grids = {}
  sObjects = {}
  THIS_AREA = "soqlArea"

  defaultDataType = ""
  defaultContentType = null

  #------------------------------------------------
  # Event on menu change
  #------------------------------------------------
  $(document).on 'displayChange', (e, param) ->
    if param.targetArea = THIS_AREA
      elementId = getActiveGridElementId()
      grid = grids[elementId]
      if grid
        grid.render()
    
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
      tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId");
      soql = $('#soqlArea #input_soql').val()
      #soql = $('#soqlArea #input_soql' + tabId).val()
      tooling = $('#soqlArea #useTooling').is(':checked')
      queryAll = $('#soqlArea #queryAll').is(':checked')      
        
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
    
  #------------------------------------------------
  # Query callbacks
  #------------------------------------------------  
  processQuerySuccess = (json) ->
    displayQueryResult(json)

  processQuerySuccessAfterCrud = (json) ->
    displayQueryResult(json)
    endCrud()

  displayQueryResult = (json) ->
    selectedTabId = json.soql_info.tab_id
    #$("#soqlArea #soql" + selectedTabId).html(json.soql_info.timestamp + json.soql_info.soql)
    #$("#soqlArea #tab" + selectedTabId).attr("soql", json.soql_info.soql)
    $("#soqlArea #soql-info" + selectedTabId).html(json.soql_info.timestamp)
    elementId = "#soqlArea #grid" + selectedTabId

    sObjects[elementId] = {
                            rows: json.records.initial_rows, 
                            columns: json.records.columns,
                            editions:{},
                            sobject_type: json.sobject,
                            soql_info: json.soql_info,
                            idColumnIndex: json.records.id_column_index,
                            editable: if json.records.id_column_index == null then false else true,
                            tempIdPrefix: json.tempIdPrefix,
                            assignedIndex: 0
                          }

    createGrid(elementId, json.records)

    if json.records.size <= 0
      grid = grids[elementId]
      grid.getPlugin('AutoColumnSize').recalculateAllColumnsWidth()
      grid.render()

  #------------------------------------------------
  # CRUD
  #------------------------------------------------
  executeCrud = (options) ->
    hideMessageArea()
    callbacks = $.getAjaxCallbacks(processCrudSuccess, processCrudError, null)
    beginCrud()
    $.executeAjax(options, callbacks)  
    
  #------------------------------------------------
  # CRUD callbacks
  #------------------------------------------------
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
  # Upsert
  #------------------------------------------------
  $('#soqlArea #upsertBtn').on 'click', (e) ->
    e.preventDefault()
    executeUpsert()
    
  executeUpsert = () ->
    if $.isAjaxBusy()
      return false
    
    elementId = getActiveGridElementId()
    sobject = sObjects[elementId]

    if !sobject || !sobject.editable || $.isEmptyObject(sobject.editions)
      return false

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

    if !sobject || !sobject.editable
      return false

    hot = grids[elementId]
    ids = getSelectedIds(hot, sobject)
    
    if ids.length <= 0
      return false
  
    val = {soql_info:sobject.soql_info, ids: ids}
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

    if !sobject || !sobject.editable
      return false

    hot = grids[elementId]
    ids = getSelectedIds(hot, sobject)
    
    if ids.length <= 0
      return false

    val = {soql_info:sobject.soql_info, ids: ids}
    action = "/undelete"
    method = "post"
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    executeCrud(options)

  #------------------------------------------------
  # Edit on grid
  #------------------------------------------------    
  detectAfterEditOnGrid = (changes, source) ->

    if source == 'loadData'
      return
    
    for change in changes
      storeChanges(change)

  storeChanges = (change) ->

    rowIndex = change[0]
    columnIndex = change[1]
    oldValue = change[2]
    newValue = change[3]

    if oldValue == newValue
      return

    isRestored = false
    isNewRow = false

    elementId = getActiveGridElementId()    
    grid = grids[elementId]
    sobject = sObjects[elementId]

    fieldName = sobject.columns[columnIndex]  
    id = getSalesforceId(grid, sobject, rowIndex)

    if id.startsWith(sobject.tempIdPrefix)
      isNewRow = true

    if sobject.editions[id]
      if !isNewRow && newValue == sobject.rows[id][columnIndex]
        delete sobject.editions[id][fieldName]
        if Object.keys(sobject.editions[id]).length <= 0
          delete sobject.editions[id]
        isRestored = true
      else
        sobject.editions[id][fieldName] = newValue
    else
      sobject.editions[id] = {}
      sobject.editions[id][fieldName] = newValue
    
    if isNewRow
      return
    
    if isRestored
      grid.removeCellMeta(rowIndex, columnIndex, 'className')
    else
      grid.setCellMeta(rowIndex, columnIndex, 'className', 'changed-cell-border')

    grid.render()

  getSalesforceId = (grid, sobject, rowIndex) ->
    idColumnIndex = sobject.idColumnIndex
    id = grid.getDataAtCell(rowIndex, idColumnIndex)

    if id == "" || id == "undefined" || id == null
      grid.getCellMeta(rowIndex, idColumnIndex).tempId
    else
      id
      
  getSelectedIds = (grid, sobject) ->
    rows = {}
    selectedCells = grid.getSelected()
    
    for range in selectedCells
      rows[range[0]] = null
      if range[0] != range[2]
        rows[range[2]] = null
    
    ids = []
    for rowIndex in Object.keys(rows)
      id = grid.getDataAtCell(rowIndex, sobject.idColumnIndex)
      ids.push(id)
     
    return ids

  #------------------------------------------------
  # Add/Remove row
  #------------------------------------------------
  $('#soqlArea').on 'click', ' .add-row', (e) ->
    addRow()
    
  addRow = () ->
    elementId = getActiveGridElementId()
    if !sObjects[elementId] || !sObjects[elementId].editable
      return

    grid = grids[elementId]
    selectedCell = getSelectedCell(grid)
    if !selectedCell || selectedCell.row < 0
      return

    grid.alter('insert_row', selectedCell.row + 1, 1)
    grid.selectCell(selectedCell.row, selectedCell.col)
  
  onAfterAddRow = (index, amount, source) ->
    setTimeout ( ->
      assignTempId(index)
    ), 3
    
  assignTempId = (rowIndex) ->
    elementId = getActiveGridElementId()
    grid = grids[elementId]
    sobject = sObjects[elementId]
    newIndex = sobject.assignedIndex + 1
    tempId = sobject.tempIdPrefix + newIndex
    sobject.assignedIndex = newIndex
    #grid.setCellMeta(selectedCell.row + 1, sobject.idColumnIndex, 'tempId', tempId)
    grid.setCellMeta(rowIndex, sobject.idColumnIndex, 'tempId', tempId)

  $('#soqlArea').on 'click', ' .remove-row', (e) ->
    removeRow()
    
  removeRow = () ->
    elementId = getActiveGridElementId()
    if !sObjects[elementId] || !sObjects[elementId].editable
      return

    grid = grids[elementId]
    selectedCell = getSelectedCell(grid)
    if !selectedCell || selectedCell.row < 0
      return false

    #sobject = sObjects[elementId]
    #tempId = grid.getCellMeta(selectedCell.row, sobject.idColumnIndex).tempId
    #if !tempId
    #  return false
    
    #if sobject.editions[tempId]
    #  delete sobject.editions[tempId]

    grid.alter('remove_row', selectedCell.row, 1)
    grid.selectCell(getValidRowAfterRemove(selectedCell, grid), selectedCell.col)
    
  onBeforeRemoveRow = (index, amount, physicalRows, source) ->
    if physicalRows.length != 1
      return false
    
    rowIndex = physicalRows[0]
    console.log(rowIndex)
    elementId = getActiveGridElementId()
    sobject = sObjects[elementId]
    grid = grids[elementId]
    tempId = grid.getCellMeta(rowIndex, sobject.idColumnIndex).tempId
    if !tempId
      return false
    
    if sobject.editions[tempId]
      delete sobject.editions[tempId]    
    
  getSelectedCell = (grid) ->
    selectedCells = grid.getSelected()

    if !selectedCells
      return {row:0,col:0}
    
    if selectedCells.length > 0 && selectedCells[0].length > 0
      {
        row: selectedCells[0][0]
        col: selectedCells[0][1]
      }
    else
      null

  getValidRowAfterRemove = (selectedCell, grid) ->
    lastRow = grid.countVisibleRows() - 1
    if selectedCell.row > lastRow
      selectedCell.row = lastRow
    else
      selectedCell.row
      
  #------------------------------------------------
  # Active grid
  #------------------------------------------------
  getActiveGridElementId = () ->
    tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    "#soqlArea #grid" + tabId
    
  getActiveGrid = () ->
    elementId = getActiveGridElementId()
    grids[elementId]

  #------------------------------------------------
  # CSV Download
  #------------------------------------------------
  $('#soqlArea #exportBtn').on 'click', (e) ->
    hotElement = getActiveGrid()
    hotElement.getPlugin('exportFile').downloadFile('csv', {
      bom: false,
      columnDelimiter: ',',
      columnHeaders: true,
      exportHiddenColumns: false,
      exportHiddenRows: false,
      fileExtension: 'csv',
      filename: 'soql_result',
      mimeType: 'text/csv',
      rowDelimiter: '\r\n',
      rowHeaders: false
    })

  #------------------------------------------------
  # Rerun SOQL
  #------------------------------------------------
  $('#soqlArea').on 'click', '.rerun', (e) ->
    if $.isAjaxBusy()
      return false

    e.preventDefault()
    
    elementId = getActiveGridElementId()
    
    if sObjects[elementId]
      executeSoql({soql_info:sObjects[elementId].soql_info, afterCrud: false})
      
  #------------------------------------------------
  # Show Query
  #------------------------------------------------
  $('#soqlArea').on 'click', '.show-query', (e) ->
    if $.isAjaxBusy()
      return false

    e.preventDefault()
    
    elementId = getActiveGridElementId()
    
    if sObjects[elementId]
      width = 750
      height = 400
      left =(screen.width - width) / 2
      top = (screen.height - height) / 2
      options = "location=0, resizable=1, menubar=0, scrollbars=1"
      options += ", left=" + left + ", top=" + top + ", width=" + width + ", height=" + height
      popup = window.open("", "soql", options)
      popup.document.write("<pre>" + sObjects[elementId].soql_info.soql  + "</pre>")
      
  #------------------------------------------------
  # Tab events
  #------------------------------------------------
  $("#soqlTabs").on "dblclick", (e) ->
    if e.target != this
      e.preventDefault()
      e.stopPropagation()
      alert("other")
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

    inputArea = '<div class="inputSoql" style="margin-bottom:-2px;" tabId="' + newTabId + '">'
    inputArea += '<textarea name="input_soql" id="input_soql' + newTabId + '" style="width:100%" rows="5"></textarea>'
    inputArea += '</div>'

    soqlArea = '<div class="resultSoql" tabId="' + newTabId + '">'    
    soqlArea += '<div id="soql' + newTabId + '">'
    soqlArea += '<button name="showQueryBtn" type="button" class="show-query btn btn-xs btn-default in-btn">Query</button>'
    soqlArea += '<button name="insRowBtn" type="button" class="add-row btn btn-xs btn-default in-btn">Insert row</button>'
    soqlArea += '<button name="remRowBtn" type="button" class="remove-row btn btn-xs btn-default in-btn">Remove row</button>'
    soqlArea += '<button name="rerunBtn" type="button" class="rerun btn btn-xs btn-default in-btn">Rerun</button>'
    soqlArea += '</div>'
    soqlArea += '<div id="soql-info' + newTabId + '">0 rows</div>'
    soqlArea += '</div>'
    
    $("#soqlArea #tabArea").append(
      "<div id=\"tab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\">" +
      #inputArea + 
      soqlArea +
      "<div id=\"grid" + newTabId + "\" class=\"resultGrid\" tabId=\"" + newTabId + "\"></div>" +
      "</div>"
    )
    
    createGrid("#soqlArea #grid" + newTabId)
    
    $("#soqlArea #tabArea").tabs("refresh")
    
    newTabIndex = $("#soqlArea #tabArea ul li").length - 1
    selectedTabId = newTabIndex
    $("#soqlArea #tabArea").tabs({ active: newTabIndex, activate: onTabSelect});

  onTabSelect = (event, ui) ->
    tabId = ui.newPanel.attr("tabId")
    elementId = "#soqlArea #grid" + tabId
    grids[elementId].render()

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
        #stretchH: stretch,
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
        afterChange: (source, changes) -> detectAfterEditOnGrid(source, changes),
        afterOnCellMouseDown: (event, coords, td) -> onCellClick(event, coords, td),
        afterCreateRow: (index, amount, source) -> onAfterAddRow(index, amount, source),
        beforeRemoveRow: (index, amount, physicalRows, source) -> onBeforeRemoveRow(index, amount, physicalRows, source)
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
    #selectedCell = coords
      
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
  $("#soqlArea #tabArea").tabs() 
  
  createTab()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
