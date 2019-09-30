coordinates = ->
  
  selectedRecords = {}
  grid = null
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
    $("#updateMetadataBtn").prop("disabled", true)
    $("#deleteMetadataBtn").prop("disabled", true)
    $("#readMetadaBtn").prop("disabled", true)
    $("#collapseMetadataTree").prop("disabled", true)
    $("#retrieveMetadataBtn").prop("disabled", true)

  getSelectedMetadata = () ->
    $('#metadataArea #selected_directory').val()

  getSelectedRecords = () ->
    JSON.stringify(Object.values(selectedRecords))

  getSelectedFullNames = () ->
    JSON.stringify(Object.keys(selectedFullNames))

  #------------------------------------------------
  # list metadata
  #------------------------------------------------
  $("#metadataArea #executListMetadataBtn").on "click", (e) ->
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
    $('#metadataArea #editMetadataTree').jstree(true).settings.core.data = null
    $('#metadataArea #editMetadataTree').jstree(true).refresh()
    selectedRecords = {}
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
    createGrid("#metadataArea #metadataGrid", json.list_grid)

  changeButtonStyles = (json) ->
    $("#updateMetadataBtn").prop("disabled", !json.api_updatable)
    $("#deleteMetadataBtn").prop("disabled", !json.api_deletable)
    $("#readMetadaBtn").prop("disabled", !json.api_readable)
    $("#collapseMetadataTree").prop("disabled", !json.api_readable)
    $("#retrieveMetadataBtn").prop("disabled", false)

  refreshTree = (json) ->
    $('#metadataArea #editMetadataTree').jstree(true).settings.core.data = json
    $('#metadataArea #editMetadataTree').jstree(true).refresh()
    $('#metadataArea #editMetadataTree').jstree(true).settings.core.data = (node, callback) -> callReadMetadata(node, callback)

  #------------------------------------------------
  # Read metadata
  #------------------------------------------------
  callReadMetadata = (node, callback) ->
    val = {crud_type: "read", metadata_type: getSelectedMetadata(), name: node.id}
    action = $("#readMetadataBtn").attr("action")
    method = "POST"
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
  $("#metadataArea #retrieveMetadataBtn").on "click", (e) ->
    if retrieveId
      return false
    
    e.preventDefault()
    checkCount = 0
    
    selected_type = getSelectedMetadata()
    selected_records = getSelectedRecords()
    val = {selected_type: selected_type, selected_records: selected_records}
    action = $("#metadataArea #retrieveMetadataBtn").attr('action')
    method ="POST"
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
      method = "POST"
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
  $("#metadataArea #deployMetadataBtn").on "click", (e) ->
    if deployId
      return false

    e.preventDefault()
    
    file = $('#metadataZipFile')[0].files[0]

    if file instanceof Blob
      $('#metadataArea #deployMetadataResultTree').jstree(true).settings.core.data = null
      $('#metadataArea #deployMetadataResultTree').jstree(true).refresh()
      getBase64(file)
    else
      displayError( {error: "Select a zip file to deploy"} )


  getBase64 = (file) ->
    reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () ->
     uploadFile(reader.result.replace(new RegExp("data:.*/.*;base64,","g"), ""))

  uploadFile = (file) ->

    checkCount = 0
    deploy_options = {}

    $("#metadataArea #deployMetadataOptions input[type=checkbox]").each ->
      key = $(this).val()
      value = $(this).prop("checked")
      deploy_options[key] = value

    val = {options: JSON.stringify(deploy_options), zip_file: file}
    action = $("#metadataArea #deployMetadataBtn").attr('action')
    method = "POST"
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
      method = "POST"
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
      callbacks = $.getAjaxCallbacks(checkDeployStatus, displayError, null)
      $.executeAjax(options, callbacks)

  deployDone = (json) ->
    deployId = null
    $('#metadataArea #deployMetadataResultTree').jstree(true).settings.core.data = json.result
    $('#metadataArea #deployMetadataResultTree').jstree(true).refresh()
    hideMessageArea()

  #------------------------------------------------
  # edit/update
  #------------------------------------------------
  $("#updateMetadataBtn").on "click", (e) ->
    e.preventDefault()
    if window.confirm("Update Metadata?")
      val = {crud_type: "update", metadata_type: getSelectedMetadata(), full_names: getSelectedFullNames()}
      action = $("#metadataArea #updateMetadataBtn").attr("action")
      method = "POST"
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
      callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null)
      $.executeAjax(options, callbacks)

  $("#metadataArea #editMetadataTree").on 'select_node.jstree', (e, data) ->
    selectedNode = data.node

  $("#metadataArea #editMetadataTree").on 'rename_node.jstree', (e, data) ->
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
    action = $("#metadataArea #editMetadataTree").attr("action")
    method = "POST"
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false)
    callbacks = $.getAjaxCallbacks(editComplete, undoEdit, null)
    $.executeAjax(options, callbacks)

  $("#readMetadaBtn").on "click", (e) ->
    if selectedNode
      $("#metadataArea #editMetadataTree").jstree(true).open_all(selectedNode)

  $("#collapseMetadataTree").on "click", (e) ->
    if selectedNode
      $("#metadataArea #editMetadataTree").jstree(true).close_all(selectedNode)

  editComplete = (json) ->
    fullName = json.full_name
    selectedFullNames[fullName] = fullName
    hideMessageArea()
    
  undoEdit = (json) ->
    node = $("#metadataArea #editMetadataTree").jstree(true).get_node(json.node_id)
    $("#metadataArea #editMetadataTree").jstree(true).edit(node, json.old_text)
    displayError(json)

  treeChecker = (operation, node, node_parent, node_position, more) ->    
    if operation == 'edit' && !node.li_attr.editable
        return false

  #------------------------------------------------
  # Delete metadata
  #------------------------------------------------
  $("#deleteMetadataBtn").on "click", (e) ->
    e.preventDefault()
    if window.confirm("Delete Metadata?")
      val = {crud_type: "delete", metadata_type: getSelectedMetadata(), selected_records: getSelectedRecords()}
      action = $("#metadataArea #deleteMetadataBtn").attr("action")
      method = "POST"
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
  # Events on table
  #------------------------------------------------
  onAfterChange = (source, changes) ->
    if changes != 'edit'
      return

    rowIndex = source[0][0]
    checked = source[0][3]

    if checked
        selectedRecords[rowIndex] = grid.getDataAtRow(rowIndex)
    else
      delete selectedRecords[rowIndex]

  #------------------------------------------------
  # HandsonTable
  #------------------------------------------------
  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    if grid
      grid.destroy()

    header = getColumns(json)
    records = getRows(json)
    columnsOption = getColumnsOption(json)
    contextMenu = getContextMenuOption(json)

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
        fillHandle: {autoInsertRow: false},
        fragmentSelection: true,
        columnSorting: true,
        afterChange: (source, changes) -> onAfterChange(source, changes),
        licenseKey: 'non-commercial-and-evaluation'
    }

    hot = new Handsontable(hotElement, hotSettings)
    hot.updateSettings afterColumnSort: ->
      hot.render()

    grid = hot

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

  getContextMenuOption = (json) ->
    if json && json.context_menu
      ["row_above", "row_below", "---------", "remove_row", "---------", "undo", "redo", "---------", "alignment"]
    else
      false

  #------------------------------------------------
  # page load actions
  #------------------------------------------------
  disableButtons()

  $("#metadataArea .tabArea").tabs()
  createGrid("#metadataArea #metadataGrid")

  $('#metadataArea #editMetadataTree').jstree({
    
    'core' : {
      'check_callback' : (operation, node, node_parent, node_position, more) -> treeChecker(operation, node, node_parent, node_position, more),
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    },
    "plugins": ["dropdown"]
  })

  $('#metadataArea #deployMetadataResultTree').jstree({
    
    'core' : {
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  })

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
