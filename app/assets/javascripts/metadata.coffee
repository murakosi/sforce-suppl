coordinates = ->
  
  selectedRecords = {}
  grids = {}
  defaultDataType = ""
  selectedNode = null
  fieldNames = null
  selectedCellOnCreateGrid = null
  del = false

  disableButtons = () ->
    $("#createButton").prop("disabled", true)
    $("#addRow").prop("disabled", true)
    $("#removeRow").prop("disabled", true)
    $("#updateButton").prop("disabled", true)
    $("#deleteButton").prop("disabled", true)
    $("#expand").prop("disabled", true)
    $("#collapse").prop("disabled", true)
    $("#retrieveButton").prop("disabled", true)

  getSelectedMetadata = () ->
    $('#metadataArea #selected_directory').val()

  getSelectedRecords = () ->
    JSON.stringify(Object.values(selectedRecords))

  getDataOnCreateGrid = () ->
    JSON.stringify(grids["#metadataArea #createGrid"].getData())

  #------------------------------------------------
  # list metadata
  #------------------------------------------------
  $("#metadataArea .execute-metadata").on "click", (e) ->
    e.preventDefault()
    listMetadate()

  listMetadate = () ->
    hideMessageArea()
    clearResults()
    val = {selected_directory: getSelectedMetadata()}
    action = $('#metadataArea .metadata-form').attr('action')
    method = $('#metadataArea .metadata-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(processListSuccessResult, processListError, null)
    $.executeAjax(options, callbacks)

  clearResults = () ->
    if $.isAjaxBusy()
      $.abortAjax()

    createGrid("#metadataArea #grid")
    createGrid("#metadataArea #createGrid")
    $('#metadataArea #editTree').jstree(true).settings.core.data = null
    $('#metadataArea #editTree').jstree(true).refresh()
    selectedRecords = {}
    grids = {}
    fieldNames = null
    selectedCellOnCreateGrid = null

  processListError = (json) ->
    disableButtons()
    displayError(json)

  processListSuccessResult = (json) ->
    hideMessageArea()
    refreshTree(json.tree)
    changeButtonStyles(json.crud_info)
    fieldNames = json.create_grid.field_names
    createGrid("#metadataArea #grid", json.list_grid)
    createGrid("#metadataArea #createGrid", json.create_grid)

  changeButtonStyles = (json) ->
    $("#createButton").prop("disabled", !json.api_creatable)
    $("#addRow").prop("disabled", !json.api_creatable)
    $("#removeRow").prop("disabled", !json.api_creatable)
    $("#updateButton").prop("disabled", !json.api_updatable)
    $("#deleteButton").prop("disabled", !json.api_deletable)
    $("#expand").prop("disabled", !json.api_readable)
    $("#collapse").prop("disabled", !json.api_readable)
    $("#retrieveButton").prop("disabled", false)

  refreshTree = (json) ->
    $('#metadataArea #editTree').jstree(true).settings.core.data = json
    $('#metadataArea #editTree').jstree(true).refresh()
    $('#metadataArea #editTree').jstree(true).settings.core.data = (node, callback) -> callReadMetadata(node, callback)

  #------------------------------------------------
  # Read metadata
  #------------------------------------------------
  callReadMetadata = (node, callback) ->
    val = {metadata_type: getSelectedMetadata(), name: node.id}
    action = $("#edit-tab").attr("action")
    method = $("#edit-tab").attr("method")
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(processReadSuccess, processReadError, callback)
    $.executeAjax(options, callbacks)

  processReadSuccess = (json, callback) ->
    hideMessageArea()
    callback(json.tree)

  processReadError = (json, callback) ->
    callback([])
    displayError(json)

  #------------------------------------------------
  # retrieve
  #------------------------------------------------
  $("#metadataArea #retrieveButton").on "click", (e) ->
    e.preventDefault()
    options = getDownloadOptions(this)
    $.ajaxDownload(options)

  getDownloadOptions = (target) ->
    url = $("#metadataArea #retrieveForm").attr('action')
    method = $("#metadataArea #retrieveForm").attr('method')
    selected_type = getSelectedMetadata()
    selected_records = getSelectedRecords()
    data = {selected_type: selected_type, selected_records: selected_records}
    $.getAjaxDownloadOptions(url, method, data, downloadDone, downloadFail, ->)

  downloadDone = (url) ->
    hideMessageArea()
  
  downloadFail = (response, url, error) ->
    displayError($.parseJSON(response))

  #------------------------------------------------
  # edit/update
  #------------------------------------------------
  $("#updateButton").on "click", (e) ->
    e.preventDefault()
    val = {crud_type: "update", metadata_type: getSelectedMetadata()}
    action = $(".crudForm").attr("action")
    method = $(".crudForm").attr("method")
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null)
    $.executeAjax(options, callbacks)

  $("#metadataArea #editTree").on 'select_node.jstree', (e, data) ->
    selectedNode = data.node

  $("#metadataArea #editTree").on 'rename_node.jstree', (e, data) ->
    if data.text == data.old
      return

    val = {
           metadata_type: getSelectedMetadata(),
           node_id: data.node.id,
           full_name: data.node.li_attr.full_name,
           path: data.node.li_attr.path,
           new_value: data.text,
           old_value: data.old,
           data_type: data.node.li_attr.data_type
          }
    action = $("#metadataArea #editTree").attr("action")
    method = $("#metadataArea #editTree").attr("method")
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(((json)->), undoEdit, null)
    $.executeAjax(options, callbacks)

  $("#expand").on "click", (e) ->
    if selectedNode == null
      return false
    $("#metadataArea #editTree").jstree(true).open_all(selectedNode)

  $("#collapse").on "click", (e) ->
    if selectedNode == null
      return false
    $("#metadataArea #editTree").jstree(true).close_all(selectedNode)

  undoEdit = (json) ->
    node = $("#metadataArea #editTree").jstree(true).get_node(json.node_id)
    $("#metadataArea #editTree").jstree(true).edit(node, json.old_text)
    displayError(json)

  treeChecker = (operation, node, node_parent, node_position, more) ->    
    if operation == 'edit' && !node.li_attr.editable
        return false

  #------------------------------------------------
  # Create metadata
  #------------------------------------------------
  $("#createButton").on "click", (e) ->
    e.preventDefault()
    val = {crud_type: "create", metadata_type: getSelectedMetadata(), field_headers: fieldNames, field_values: getDataOnCreateGrid()}
    action = $(".crudForm").attr("action")
    method = $(".crudForm").attr("method")
    options = $.getAjaxOptions(action, method, val, "json")
    callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null)
    $.executeAjax(options, callbacks)

  $("#addRow").on "click", (e) ->
    grid = grids["#metadataArea #createGrid"]
    if !selectedCellOnCreateGrid? || selectedCellOnCreateGrid.row < 0
      return false
    else
      grid.alter('insert_row', selectedCellOnCreateGrid.row + 1, 1)
      grid.selectCell(selectedCellOnCreateGrid.row, selectedCellOnCreateGrid.col)

  $("#removeRow").on "click", (e) ->
    grid = grids["#metadataArea #createGrid"]
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

  #------------------------------------------------
  # Delete metadata
  #------------------------------------------------
  $("#deleteButton").on "click", (e) ->
    e.preventDefault()
    if window.confirm("Are you sure to delete Metadata?")
      val = {crud_type: "delete", metadata_type: getSelectedMetadata(), selected_records: getSelectedRecords()}
      action = $(".crudForm").attr("action")
      method = $(".crudForm").attr("method")
      options = $.getAjaxOptions(action, method, val, defaultDataType)
      callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null)
      $.executeAjax(options, callbacks)

  #------------------------------------------------
  # Crud success/error
  #------------------------------------------------
  saveSuccess = (json) ->
    hideMessageArea()
    alert(json.message)
    if json.refresh_required
      listMetadate()

  #------------------------------------------------
  # message
  #------------------------------------------------
  displayError = (json) ->
    $("#metadataArea #messageArea").html(json.error)
    $("#metadataArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#metadataArea #messageArea").empty()
    $("#metadataArea #messageArea").hide()

  #------------------------------------------------
  # HandsonTable
  #------------------------------------------------
  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    if grids[elementId]
      table = grids[elementId]
      table.destroy()

    header = getColumns(json)
    records = getRows(json)
    columnsOption = getColumnsOption(json)
    contextMenu = getContextMenuOption(json)
    minRow = getMinRow(json)
    allowSort = getAllowSort(elementId)
    beforeChangeFunc = getBeforeChangeFunc(elementId)
    onClickFunc = getOnClickFunc(elementId, json)

    hotSettings = {
        data: records,
        height: 500,
        stretchH: 'all',
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
        #contextMenu: contextMenu,
        columnSorting: allowSort,
        beforeChange: (source, changes) -> beforeChangeFunc(source, changes),
        afterOnCellMouseDown: (event, coords, td) -> onClickFunc(event, coords, td)
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

  getColumnsOption = (json) ->
    if !json?
      [[]]
    else
      json.column_options

  getContextMenuOption = (json) ->
    if json && json.context_menu
      ["row_above", "row_below", "---------", "remove_row", "---------", "undo", "redo", "---------", "alignment"]
    else
      false

  getMinRow = (json) ->
    if json && json.min_row
      json.min_row
    else
      0

  getAllowSort = (elementId) ->
    if elementId == "#metadataArea #createGrid"
      false
    else
      true

  getBeforeChangeFunc = (elementId) ->
    if elementId != "#metadataArea #grid"
      return (source, changes) ->

    return detectBeforeEditOnGrid

  detectBeforeEditOnGrid = (source, changes) ->
    if changes != 'edit'
      return

    rowIndex = source[0][0]
    checked = source[0][3]

    if checked
        selectedRecords[rowIndex] = grids["#metadataArea #grid"].getDataAtRow(rowIndex)
    else
      delete selectedRecords[rowIndex]

  getOnClickFunc = (elementId, json) ->
    if !json? || elementId != "#metadataArea #createGrid"
      return (event, coords, td) ->
  
    return onCellClick

  onCellClick = (event, coords, td) ->
    selectedCellOnCreateGrid = coords

  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  disableButtons()

  $("#metadataArea #tabArea").tabs()

  createGrid("#metadataArea #grid")
  createGrid("#metadataArea #createGrid")

  $('#metadataArea #editTree').jstree({
    
    'core' : {
      'check_callback' : (operation, node, node_parent, node_position, more) -> treeChecker(operation, node, node_parent, node_position, more),
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    },
    "plugins": ["dropdown"]
  })

  $("#metadataArea #tabArea").tabs({ active: 1 });
  #$("#metadataArea #tabArea").tabs();

$(document).ready(coordinates)
$(document).on('page:load', coordinates)