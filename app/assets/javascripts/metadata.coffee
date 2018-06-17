coordinates = ->
  
  fullNames = {}
  FULL_NAME_INDEX = 4
  grids = {}
  rawData = {}
  currentId = null
  defaultDataType = ""
  selectedNode = null
  fieldNames = null
  selectedCellOnCreateGrid = null

  downloadOptions = (url, method, data, successCallback, failCallback, alwaysCallback) ->
    {
      "url": url,
      "method": method,
      "data": data,
      "successCallback": successCallback,
      "failCallback": failCallback,
      "alwaysCallback": alwaysCallback
    }

  $("#metadataArea .exp").on "click", (e) ->
    e.preventDefault()
    options = getDownloadOptions(this)
    $.ajaxDownload(options)

  getDownloadOptions = (target) ->
    url = $("#metadataArea #exportForm").attr('action')
    method = $("#metadataArea #exportForm").attr('method')
    dl_format = $(target).attr("dl_format")
    selected_type = getSelectedMetadata()
    full_names = getFullNames()
    data = {dl_format: dl_format, selected_type: selected_type, full_names: full_names}
    $.getAjaxDownloadOptions(url, method, data, downloadDone, downloadFail, ->)

  downloadDone = (url) ->
    hideMessageArea()
  
  downloadFail = (response, url, error) ->
    displayError($.parseJSON(response))

  getSelectedMetadata = () ->
    $('#metadataArea #selected_directory').val()

  getFullNames = () ->
    Object.values(fullNames)

  getDataOnCreateGrid = () ->
    JSON.stringify(grids["#metadataArea #createGrid"].getData())

  $("#metadataArea #editTree").on "before_open.jstree", (e, node) ->
    if currentId == node.node.id
      return

    if rawData[node.node.id]
      setRawData(rawData[node.node.id])

  $("#metadataArea .execute-metadata").on "click", (e) ->
    e.preventDefault()
    clearResults()
    val = {selected_directory: getSelectedMetadata()}
    action = $('#metadataArea .metadata-form').attr('action')
    method = $('#metadataArea .metadata-form').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(processListSuccessResult, displayError, (->))
    $.executeAjax(options, callbacks)

  clearResults = () ->
    if $.isAjaxBusy()
      $.abortAjax()

    createGrid("#metadataArea #grid")
    createGrid("#metadataArea #createGrid")
    $('#metadataArea #editTree').jstree(true).settings.core.data = null
    $('#metadataArea #editTree').jstree(true).refresh()
    fullNames = {}
    rawData = {}
    grids = {}
    fieldNames = null
    currentId = null
    selectedCellOnCreateGrid = null

  displayError = (json) ->
    $("#metadataArea #messageArea").html(json.error)
    $("#metadataArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#metadataArea #messageArea").empty()
    $("#metadataArea #messageArea").hide()

  processListSuccessResult = (json) ->
    hideMessageArea()
    refreshTree(json.tree)
    changeButtonStyles(json.crud_info)
    fieldNames = json.create_grid.field_names
    createGrid("#metadataArea #grid", json.list_grid)
    createGrid("#metadataArea #createGrid", json.create_grid)

  $("#metadataArea #list").on "click", (e) ->
    #console.log(grids["#metadataArea #grid"])
    #grids["#metadataArea #grid"].render();
    $("#metadataArea #grid").focus()

  $("#metadataArea #create").on "click", (e) ->
    #console.log(grids["#metadataArea #grid"])
    #grids["#metadataArea #createGrid"].render();

  changeButtonStyles = (json) ->
    $("#createButton").prop("disabled", !json.api_creatable)
    $("#addRow").prop("disabled", !json.api_creatable)
    $("#removeRow").prop("disabled", !json.api_creatable)
    $("#updateButton").prop("disabled", !json.api_updatable)
    $("#deleteButton").prop("disabled", !json.api_deletable)

  refreshTree = (json) ->
    $('#metadataArea #editTree').jstree(true).settings.core.data = json
    $('#metadataArea #editTree').jstree(true).refresh()
    $('#metadataArea #editTree').jstree(true).settings.core.data = (node, cb) -> callReadMetadata(node, cb)

  $("#addRow").on "click", (e) ->
    grid = grids["#metadataArea #createGrid"]
    #if grid.getSelected() == undefined
    if !selectedCellOnCreateGrid? || selectedCellOnCreateGrid.row < 0
      return false
    else
      #grid.alter('insert_row', grid.getSelected()[0][0] + 1, 1)
      grid.alter('insert_row', selectedCellOnCreateGrid.row + 1, 1)
      grid.selectCell(selectedCellOnCreateGrid.row, selectedCellOnCreateGrid.col)

  #cell arrays [[startRow, startCol, endRow, endCol], ...]
  $("#removeRow").on "click", (e) ->
    grid = grids["#metadataArea #createGrid"]
    if grid.getSelected() == undefined
      return false
    else
      grid.alter('remove_row', grid.getSelected()[0][0], 1)

  callReadMetadata = (node, callback) ->
    currentId = node.id
    val = {metadata_type: getSelectedMetadata(), name: node.id}
    action = $("#edit-tab").attr("action")
    method = $("#edit-tab").attr("method")
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(processReadSuccess, processReadError, (->), callback)
    $.executeAjax(options, callbacks)

  processReadSuccess = (json, callback) ->
    hideMessageArea
    rawData[currentId] = json.raw
    setRawData(json.raw)
    callback(json.tree)

  processReadError = (json, callback) ->
    callback([])
    $("#metadataArea #messageArea").html(json.error)
    $("#metadataArea #messageArea").show()

  setRawData = (json) ->
    $("#raw").empty()
    $("#raw").html(JSON.stringify(json))

  $("#updateButton").on "click", (e) ->
    e.preventDefault()
    val = {crud_type: "update", metadata_type: getSelectedMetadata()}
    action = $(".crudForm").attr("action")
    method = $(".crudForm").attr("method")
    options = $.getAjaxOptions(action, method, val, defaultDataType)
    callbacks = $.getAjaxCallbacks(saveSuccess, displayError, ->)
    $.executeAjax(options, callbacks)

  $("#deleteButton").on "click", (e) ->
    e.preventDefault()
    if window.confirm("Are you sure to delete Metadata?")
      val = {crud_type: "delete", metadata_type: getSelectedMetadata(), full_names: getFullNames()}
      action = $(".crudForm").attr("action")
      method = $(".crudForm").attr("method")
      options = $.getAjaxOptions(action, method, val, defaultDataType)
      callbacks = $.getAjaxCallbacks(saveSuccess, displayError, ->)
      $.executeAjax(options, callbacks)

  $("#createButton").on "click", (e) ->
    e.preventDefault()
    val = {crud_type: "create", metadata_type: getSelectedMetadata(), field_headers: fieldNames, field_values: getDataOnCreateGrid()}
    action = $(".crudForm").attr("action")
    method = $(".crudForm").attr("method")
    options = $.getAjaxOptions(action, method, val, "json")
    callbacks = $.getAjaxCallbacks(saveSuccess, displayError, ->)
    $.executeAjax(options, callbacks)

  saveSuccess = (json) ->
    hideMessageArea()
    alert(json.message)

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
    callbacks = $.getAjaxCallbacks(((json)->), undoEdit, ->)
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
        #minRow: minRow,
        #minSpareRows: minRow,
        columnSorting: true,
        #outsideClickDeselects: false,
        beforeChange: (source, changes) -> detectBeforeEditOnGrid(source, changes),
        afterOnCellMouseDown: (event, coords, td) -> onClickFunc(event, coords, td)
    }

    grids[elementId] = new Handsontable(hotElement, hotSettings)
    
  getOnClickFunc = (elementId, json) ->
    if !json? || elementId != "#metadataArea #createGrid"
      return ((event, coords, td) ->)
  
    return onCellClick

  onCellClick = (event, coords, td) ->
    console.log(coords)
    selectedCellOnCreateGrid = coords
    
  detectBeforeEditOnGrid = (source, changes) ->
    if changes != 'edit'
      return

    rowIndex = source[0][0]
    checked = source[0][3]

    if checked
        fullNames[rowIndex] = getFullName(rowIndex)
    else
      delete fullNames[rowIndex]

  getFullName = (rowIndex) ->
      record = grids["#metadataArea #grid"].getDataAtRow(rowIndex)
      record[FULL_NAME_INDEX]

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
    }  
  })

  $("#metadataArea #tabArea").tabs({ active: 2 });

$(document).ready(coordinates)
$(document).on('page:load', coordinates)