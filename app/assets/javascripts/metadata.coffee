coordinates = ->
  
  selectedRecords = {}
  grids = {}
  defaultDataType = ""
  defaultContentType = null
  selectedFullNames = {}
  selectedNode = null
  fieldNames = null
  fieldTypes = null
  deployId = null
  retrieveId = null
  checkInterval = 2000
  checkCount = 0;

  disableButtons = () ->
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

    createGrid("#metadataArea #metadataGrid")
    $('#metadataArea #editTree').jstree(true).settings.core.data = null
    $('#metadataArea #editTree').jstree(true).refresh()
    selectedRecords = {}
    grids = {}
    fieldNames = null
    fieldTypes = null
    selectedFullNames = {}
    selectedNode = null

  processListError = (json) ->
    disableButtons()
    displayError(json)

  processListSuccessResult = (json) ->
    hideMessageArea()
    refreshTree(json.tree)
    changeButtonStyles(json.crud_info)
    fieldNames = json.create_grid.field_names
    fieldTypes = json.create_grid.field_types
    createGrid("#metadataArea #metadataGrid", json.list_grid)

  changeButtonStyles = (json) ->
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
    if retrieveId
      return false
    
    e.preventDefault()
    checkCount = 0
    
    selected_type = getSelectedMetadata()
    selected_records = getSelectedRecords()
    val = {selected_type: selected_type, selected_records: selected_records}
    action = $("#metadataArea #retrieveForm").attr('action')
    method = $("#metadataArea #retrieveForm").attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(checkRetrieveStatus, displayError, null)
    $.executeAjax(options, callbacks)
    
  checkRetrieveStatus = (json) ->
    if json.done
      retrieveDone(json)
    else
      retrieveId = json.id
      checkCount++
      sleep(checkInterval * checkCount);      
      val = {id: retrieveId}
      action = "metadata/retrieve_check"
      method = "post"
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
      callbacks = $.getAjaxCallbacks(checkRetrieveStatus, displayError, null)
      $.executeAjax(options, callbacks)

  sleep = (waitMsec) ->
    startMsec = new Date()
    while new Date - startMsec < waitMsec
      return

  retrieveDone = (json) ->
    retrieveId = null
    url = "metadata/retrieve_result"
    method = "post"
    options = $.getAjaxDownloadOptions(url, method, null, downloadDone, downloadFail, ->)
    $.ajaxDownload(options)
    
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
      $('#metadataArea #deployResultTree').jstree(true).settings.core.data = null
      $('#metadataArea #deployResultTree').jstree(true).refresh()
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

  deployDone = (json) ->
    deployId = null
    $('#metadataArea #deployResultTree').jstree(true).settings.core.data = json.result
    $('#metadataArea #deployResultTree').jstree(true).refresh()
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
    if selectedNode
      $("#metadataArea #editTree").jstree(true).open_all(selectedNode)

  $("#collapse").on "click", (e) ->
    if selectedNode
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
    retrieveId = null
    deployId = null
    $("#metadataArea .messageArea").html(json.error)
    $("#metadataArea .messageArea").show()
  
  hideMessageArea = () ->
    $("#metadataArea .messageArea").empty()
    $("#metadataArea .messageArea").hide()

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

    hotSettings = {
        data: records,
        height: 500,
        stretchH: 'all',
        autoWrapRow: true,
        allowRemoveColumn: false,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: rowHeaderOption,
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

  $("#metadataArea .tabArea").tabs()
  createGrid("#metadataArea #metadataGrid")

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

  $('#metadataArea #deployResultTree').jstree({
    
    'core' : {
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  })

  #$("#metadataArea #tabArea").tabs();

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
