coordinates = ->
  
  selectedRowData = {}
  grids = {}
  nodeGrids = {}
  currentId = null
  jqXHR = null
  defaultDataType = ""
  selectedNode = null

  getAjaxOptions = (action, method, data, datatype) ->
    {
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }

  downloadOptions = (url, method, data, successCallback, failCallback, alwaysCallback) ->
    {
      "url": url,
      "method": method,
      "data": data,
      "successCallback": successCallback,
      "failCallback": failCallback,
      "alwaysCallback": alwaysCallback
    }

  $("#metadataArea .exp-btn").on "click", (e) ->
    e.preventDefault()
    options = getDownloadOptions(this)
    $.ajaxDownload(options)

  getDownloadOptions = (target) ->
    url = $("#metadataArea #exportForm").attr('action')
    method = $("#metadataArea #exportForm").attr('method')
    dl_format = $(target).attr("dl_format")
    selected_type = $('#metadataArea #selected_directory').val()
    selected_record = selectedRowData
    data = {dl_format: dl_format, selected_type: selected_type, selected_record: selected_record}
    downloadOptions(url, method, data, downloadDone, downloadFail, ->)

  downloadDone = (url) ->
    hideMessageArea()
  
  downloadFail = (response, url, error) ->
    displayError($.parseJSON(response))

  $("#metadataArea #tree").on "before_open.jstree", (e, node) ->
    if currentId == node.node.id
      return

    if nodeGrids[node.node.id]
      console.error(nodeGrids[node.node.id])
      createGrid("#metadataArea #sample", nodeGrids[node.node.id])

  $("#metadataArea .execute-metadata").on "click", (e) ->
    e.preventDefault()
    clearResults()
    val = {selected_directory: $('#metadataArea #selected_directory').val()}
    action = $('#metadataArea .metadata-form').attr('action')
    method = $('#metadataArea .metadata-form').attr('method')
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, processListSuccessResult, displayError)

  clearResults = () ->
    createGrid("#metadataArea #grid")
    createGrid("#metadataArea #sample")
    $('#metadataArea #tree').jstree(true).settings.core.data = null
    $('#metadataArea #tree').jstree(true).refresh()
    # to eidt
    $('#metadataArea #editTree').jstree(true).settings.core.data = null
    $('#metadataArea #editTree').jstree(true).refresh()
    # ==============
    selectedRowData = {}
    nodeGrids = {}
    grids = {}
    currentId = null
    
  executeAjax = (options, doneCallback, errorCallback, params = null) ->

    if jqXHR
      return

    jqXHR = $.ajax({
      url: options.action
      type: options.method
      data: options.data
      dataType: options.datatype
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      jqXHR = null
      console.log { done: stat, data: data, xhr: xhr }
      doneCallback($.parseJSON(xhr.responseText), params)

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      errorCallback($.parseJSON(xhr.responseText), params)

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  displayError = (json) ->
    $("#metadataArea #messageArea").html(json.error)
    $("#metadataArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#metadataArea #messageArea").empty()
    $("#metadataArea #messageArea").hide()

  processListSuccessResult = (json) ->
    hideMessageArea()
    refreshTree(json.tree)
    createGrid("#metadataArea #grid", json.grid)

  refreshTree = (json) ->
    $('#metadataArea #tree').jstree(true).settings.core.data = json
    $('#metadataArea #tree').jstree(true).refresh()
    $('#metadataArea #tree').jstree(true).settings.core.data = (node, cb) -> callReadMetadata(node, cb)
    # to edit
    $('#metadataArea #editTree').jstree(true).settings.core.data = json
    $('#metadataArea #editTree').jstree(true).refresh()
    $('#metadataArea #editTree').jstree(true).settings.core.data = (node, cb) -> callReadMetadata2(node, cb)

  callReadMetadata = (node, callback) ->
    val = {metadata_type: $('#metadataArea #selected_directory').val(), name: node.id}
    action = $("#read-tab").attr("action")
    method = $("#read-tab").attr("method")
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, processReadSuccess, processReadError, callback)

  processReadSuccess = (json, callback) ->
    hideMessageArea
    currentId = json.fullName
    nodeGrids[currentId] = json.grid
    createGrid("#metadataArea #sample", json.grid)
    callback(json.tree)

  processReadError = (json, callback) ->
    callback([])
    $("#metadataArea #messageArea").html(json.error)
    $("#metadataArea #messageArea").show()    
  
  # to edit ==================================
  callReadMetadata2 = (node, callback) ->
    val = {metadata_type: $('#metadataArea #selected_directory').val(), name: node.id}
    action = $("#edit-tab").attr("action")
    method = $("#edit-tab").attr("method")
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, processReadSuccess2, processReadError, callback)

  processReadSuccess2 = (json, callback) ->
    hideMessageArea
    callback(json.tree)    

  $("#saveButton").on "click", (e) ->
    val = {metadata_type: $('#metadataArea #selected_directory').val()}
    action = $(this).attr("action")
    method = $(this).attr("method")
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, saveSuccess, displayError)

  saveSuccess = (json) ->
    alert("Saved")

  $("#metadataArea #editTree").on 'select_node.jstree', (e, data) ->
    selectedNode = data.node

  $("#metadataArea #editTree").on 'rename_node.jstree', (e, data) ->
    if data.text == data.old
      return

    val = {
           metadata_type: $('#metadataArea #selected_directory').val(),
           node_id: data.node.id,
           full_name: data.node.li_attr.full_name,
           path: data.node.li_attr.path,
           new_value: data.text,
           old_value: data.old,
           data_type: data.node.li_attr.data_type
          }
    action = $("#metadataArea #editTree").attr("action")
    method = $("#metadataArea #editTree").attr("method")
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, doneEdit, undoEdit)    

  $("#expand").on "click", (e) ->
    if selectedNode == null
      return false
    $("#metadataArea #editTree").jstree(true).open_all(selectedNode)

  $("#collapse").on "click", (e) ->
    if selectedNode == null
      return false
    $("#metadataArea #editTree").jstree(true).close_all(selectedNode)

  doneEdit = (json) ->

  undoEdit = (json) ->
    node = $("#metadataArea #editTree").jstree(true).get_node(json.node_id)
    $("#metadataArea #editTree").jstree(true).edit(node, json.old_text)
    displayError(json)

  treeChecker = (operation, node, node_parent, node_position, more) ->
    if operation == 'edit' && !node.li_attr.editable
      return false

  # end edit =================================

  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    if grids[elementId]
      table = grids[elementId]
      table.destroy()

    header = getColumns(json)
    records = getRows(json)
    columnsOption = getColumnsOption(json)

    hotSettings = {
        data: records,
        height: 500;
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columnsOption,
        contextMenu: false,
        startRows: 0,
        beforeChange: (source, changes) -> detectBeforeEditOnGrid(source, changes)
    }

    grids[elementId] = new Handsontable(hotElement, hotSettings)

  detectBeforeEditOnGrid = (source, changes) ->
    if changes != 'edit'
      return

    rowIndex = source[0][0]
    checked = source[0][3]

    if checked
      if Object.keys(selectedRowData).length > 0
        source[0][3] = false
        return
      else
        selectedRowData[rowIndex] = grids["#metadataArea #grid"].getDataAtRow(rowIndex)
        return
    else
      delete selectedRowData[rowIndex]
      return

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

  tes = (a,b) ->
    alert("ehre")
    false

  $("#metadataArea #tabArea").tabs()

  createGrid("#metadataArea #grid")
  createGrid("#metadataArea #sample")

  $('#metadataArea #editTree').jstree({
    
    'core' : {
      'check_callback' : (operation, node, node_parent, node_position, more) -> treeChecker(operation, node, node_parent, node_position, more),
      'data' : [ 
        { 'id' : '1', 'parent' : '#', 'text' : 'Root node 1' },
        { 'id' : '2', 'parent' : '1', 'text' : 'Child node 1' },
        { 'id' : '3', 'parent' : '1', 'text' : 'Child node 2' },
        { 'id' : '4', 'parent' : '#', 'text' : 'Root node 2' }
      ],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  })

  $('#metadataArea #tree').jstree({
    'core' : {
      'check_callback' : true,
      'data' : [ # 画面に表示する仮の初期データ
        { 'id' : '1', 'parent' : '#', 'text' : 'Root node 1' },
        { 'id' : '2', 'parent' : '1', 'text' : 'Child node 1' },
        { 'id' : '3', 'parent' : '1', 'text' : 'Child node 2' },
        { 'id' : '4', 'parent' : '#', 'text' : 'Root node 2' }
      ],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  })

$(document).ready(coordinates)
$(document).on('page:load', coordinates)