coordinates = ->
  
  selectedTabId = 0
  currentTabIndex = 0
  selectedCellOnCreateGrid = null
  grids = {}
  soqls = {}

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
    if e.ctrlKey && e.key == 'r'
      e.preventDefault()
      if e.target.id == "input_soql"        
        executeSoql()
  
  #------------------------------------------------
  # Execute SOQL
  #------------------------------------------------
  $('#soqlArea .execute-soql').on 'click', (e) ->
    e.preventDefault()
    executeSoql()
    
  executeSoql = () ->
    if jqXHR
      return false
    
    hideMessageArea()
    selectedTabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId");
    val = {soql: $('#soqlArea #input_soql').val(), tooling: $('#soqlArea #useTooling').is(':checked')}
    action = $('#soqlArea .execute-form').attr('action')
    method = $('#soqlArea .execute-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)
  
  processSuccessResult = (json) ->
    $("#soqlArea #soql" + selectedTabId).html(json.soql)
    elementId = "#soqlArea #grid" + selectedTabId
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
      "<div id=\"tab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\" sobject=\"\" >" +
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

  getActiveGrid = () ->
    tabId = $("#soqlArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    elementId = "#soqlArea #grid" + tabId
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
    rowHeaderWidth = getRowHeaderWidth(elementId, json)
    minRow = getMinRow(json)

    hotSettings = {
        data: records,
        height: 500,
        stretchH: 'all',
        autoWrapRow: true,
        allowRemoveColumn: false,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        rowHeaderWidth: rowHeaderWidth,
        colHeaders: header,
        columns: columnsOption,
        startRows: 0,
        minRows: minRow,
        minSpareRows: 0,
        minSpareCols: 0,
        fillHandle: {autoInsertRow: false},
        fragmentSelection: true,
        columnSorting: true,
        licenseKey: 'non-commercial-and-evaluation'
        afterChange: (source, changes) -> detectAfterEditOnGrid(source, changes),
        afterOnCellMouseDown: (event, coords, td) -> onCellClick(event, coords, td)
    }

    hot = new Handsontable(hotElement, hotSettings)
    hot.updateSettings afterColumnSort: ->
      hot.render()

    grids[elementId] = hot

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

  getRowHeaderWidth = (elementId, json) ->
    if !json || !json.profiles
      return null
      
    widths = []
    for value in json.profiles
      widths.push(getTextWidth(value, "10pt Verdana,Arial,sans-serif"))
    Math.max.apply(null, widths)

  getTextWidth = (text, font) ->
    canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    context = canvas.getContext("2d");
    context.font = font;
    metrics = context.measureText(text);
    return metrics.width;

  getMinRow = (json) ->
    if json && json.min_row
      json.min_row
    else
      0

  detectAfterEditOnGrid = (source, changes) ->
    if changes != 'edit'
      return

    rowIndex = source[0][0]
    checked = source[0][3]

    #if checked
    #    selectedRecords[rowIndex] = grids["#metadataArea #grid"].getDataAtRow(rowIndex)
    #else
    #  delete selectedRecords[rowIndex]
    console.log("changed")
    console.log(source)

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
