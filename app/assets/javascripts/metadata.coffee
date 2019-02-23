coordinates = ->
  
  selectedRecords = {}
  grids = {}
  defaultDataType = ""
  defaultContentType = null
  selectedFullNames = {}
  selectedNode = null
  fieldNames = null
  fieldTypes = null
  selectedCellOnCreateGrid = null
  deployId = null
  checkInterval = 2000
  checkCount = 0;

  disableButtons = () ->
    $("#createButton").prop("disabled", true)
    $("#addRow").prop("disabled", true)
    $("#removeRow").prop("disabled", true)
    $("#clearGrid").prop("disabled", true)
    $("#updateButton").prop("disabled", true)
    $("#deleteButton").prop("disabled", true)
    $("#expand").prop("disabled", true)
    $("#collapse").prop("disabled", true)
    $("#retrieveButton").prop("disabled", true)

  getSelectedMetadata = () ->
    $('#metadataArea #selected_directory').val()

  getSelectedRecords = () ->
    JSON.stringify(Object.values(selectedRecords))

  getSelectedFullNames = () ->
    JSON.stringify(Object.keys(selectedFullNames))

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
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
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
    fieldTypes = null
    selectedFullNames = {}
    selectedNode = null
    selectedCellOnCreateGrid = null

  processListError = (json) ->
    disableButtons()
    displayError(json)

  processListSuccessResult = (json) ->
    hideMessageArea()
    refreshTree(json.tree)
    changeButtonStyles(json.crud_info)
    fieldNames = json.create_grid.field_names
    fieldTypes = json.create_grid.field_types
    createGrid("#metadataArea #grid", json.list_grid)
    createGrid("#metadataArea #createGrid", json.create_grid)

  changeButtonStyles = (json) ->
    $("#createButton").prop("disabled", !json.api_creatable)
    $("#addRow").prop("disabled", !json.api_creatable)
    $("#removeRow").prop("disabled", !json.api_creatable)
    $("#clearGrid").prop("disabled", !json.api_creatable)
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
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false)
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
  # deploy
  #------------------------------------------------
  $("#metadataArea #deployButton").on "click", (e) ->
    if deployId
      return false

    e.preventDefault()
    
    file = $('#zipFile')[0].files[0]

    if file instanceof Blob
      $('#metadataArea #deployResultGrid').jstree(true).settings.core.data = null
      $('#metadataArea #deployResultGrid').jstree(true).refresh()
      getBase64(file)
    else
      displayError( {error: "Select file to deploy"} )


  getBase64 = (file) ->
    reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () ->
     uploadFile(reader.result.replace(new RegExp("data:.*/.*;base64,","g"), ""))

  uploadFile = (file) ->

    checkCount = 0
    deploy_options = {}

    $("#metadataArea #deployOptions input[type=checkbox]").each ->
      key = $(this).val()
      value = $(this).prop("checked")
      deploy_options[key] = value

    val = {options: JSON.stringify(deploy_options), zip_file: file}
    action = $("#metadataArea #deployForm").attr('action')
    method = $("#metadataArea #deployForm").attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(checkDeployStatus, displayError, null)
    $.executeAjax(options, callbacks)

  checkDeployStatus = (json) ->
    if json.done
      deployDone(json)
    else
      deployId = json.id
      checkCount++
      sleep(checkInterval * checkCount);      
      val = {id: deployId}
      action = "metadata/deploy_check"
      method = "post"
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
      callbacks = $.getAjaxCallbacks(checkDeployStatus, displayError, null)
      $.executeAjax(options, callbacks)

  sleep = (waitMsec) ->
    startMsec = new Date()
    while new Date - startMsec < waitMsec
      return

  deployDone = (json) ->
    console.log(json.result)
    deployId = null
    #createGrid("#metadataArea #deployResultGrid", json.result)
    $('#metadataArea #deployResultGrid').jstree(true).settings.core.data = json.result
    $('#metadataArea #deployResultGrid').jstree(true).refresh()
    hideMessageArea()

  #------------------------------------------------
  # edit/update
  #------------------------------------------------
  $("#updateButton").on "click", (e) ->
    e.preventDefault()
    if window.confirm("Update Metadata?")
      val = {crud_type: "update", metadata_type: getSelectedMetadata(), full_names: getSelectedFullNames()}
      action = $(".crudForm").attr("action")
      method = $(".crudForm").attr("method")
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
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
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false)
    callbacks = $.getAjaxCallbacks(editComplete, undoEdit, null)
    $.executeAjax(options, callbacks)

  $("#expand").on "click", (e) ->
    if selectedNode == null
      return false
    $("#metadataArea #editTree").jstree(true).open_all(selectedNode)

  $("#collapse").on "click", (e) ->
    if selectedNode == null
      return false
    $("#metadataArea #editTree").jstree(true).close_all(selectedNode)

  editComplete = (json) ->
    fullName = json.full_name
    selectedFullNames[fullName] = fullName
    hideMessageArea()
    
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
    val = {
           crud_type: "create",
           metadata_type: getSelectedMetadata(),
           field_headers: fieldNames,
           field_types: fieldTypes,
           field_values: getDataOnCreateGrid()
          }
    action = $(".crudForm").attr("action")
    method = $(".crudForm").attr("method")
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null)
    $.executeAjax(options, callbacks)

  $("#clearGrid").on "click", (e) ->
    grid = grids["#metadataArea #createGrid"]
    grid.clear()

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
    if window.confirm("Delete Metadata?")
      val = {crud_type: "delete", metadata_type: getSelectedMetadata(), selected_records: getSelectedRecords()}
      action = $(".crudForm").attr("action")
      method = $(".crudForm").attr("method")
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
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
    deployId = null
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
    rowHeaderOption = getRowHeaderOption(elementId, json)
    rowHeaderWidth = getRowHeaderWidth(elementId, json)
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
        #rowHeaders: true,
        rowHeaders: rowHeaderOption,
        rowHeaderWidth: rowHeaderWidth,
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

  getRowHeaderOption = (elementId, json) ->
    if json && json.profiles
      json.profiles
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
  # Custom renderer
  #------------------------------------------------
  customDropdownRenderer = (instance, td, row, col, prop, value, cellProperties) ->
    optionsList = cellProperties.chosenOptions.data
    splitter = cellProperties.chosenOptions.splitter
    
    if(typeof optionsList == "undefined" || typeof optionsList.length == "undefined" || !optionsList.length)
      Handsontable.TextCell.renderer(instance, td, row, col, prop, value, cellProperties);
      return td;
    
    valueArray = $.map((value + '').split(splitter), $.trim)
    newValue = []
    index = 0

    while index < optionsList.length
      if valueArray.indexOf(optionsList[index].id + '') > -1
        newValue.push optionsList[index].label
      index++

    if newValue.length
      value = newValue.join(splitter + " ")

    Handsontable.renderers.TextRenderer.apply(this, arguments);

    return td

  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  disableButtons()

  $("#metadataArea #tabArea").tabs()

  Handsontable.renderers.registerRenderer('customDropdownRenderer', customDropdownRenderer);

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

  $('#metadataArea #deployResultGrid').jstree({
    
    'core' : {
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  })

  #$("#metadataArea #tabArea").tabs({ active: 2 });
  $("#metadataArea #tabArea").tabs();

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
