coordinates = ->
  
  selectedTabId = 1
  selectedRowData = {}
  grids = {}
  nodeGrids = {}
  currentId = null
  jqXHR = null
  
  get_options = (action, method, data, datatype, doAsync = true) ->
    {
      "async" : doAsync,
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }
 
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
    options = get_options(action, method, val)
    executeAjax(options, processListSuccessResult, displayError)

  clearResults = () ->
    createGrid("#metadataArea #grid")
    createGrid("#metadataArea #sample")
    $('#metadataArea #tree').jstree(true).settings.core.data = null
    $('#metadataArea #tree').jstree(true).refresh()
    selectedRowData = {}
    nodeGrids = {}
    grids = {}
    currentId = null
    
  executeAjax = (options, doneCallback, errorCallback, params = null) ->

    if jqXHR
      return

    jqXHR = $.ajax({
      async: true
      url: options.action
      type: options.method
      data: options.data
      dataType: options.datatype
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      jqXHR = null
      console.log { done: stat, data: data, xhr: xhr }
      $("#metadataArea #messageArea").empty()
      $("#metadataArea #messageArea").hide()
      doneCallback($.parseJSON(xhr.responseText), params)

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      alert(err)
      errorCallback($.parseJSON(xhr.responseText))

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  displayError = (json) ->
    $("#metadataArea #messageArea").html(json.error)
    $("#metadataArea #messageArea").show()
  
  processListSuccessResult = (json) ->
    refreshTree(json.tree)
    createGrid("#metadataArea #grid", json.grid)

  refreshTree = (json) ->
    $('#metadataArea #tree').jstree(true).settings.core.data = json
    $('#metadataArea #tree').jstree(true).refresh()
    $('#metadataArea #tree').jstree(true).settings.core.data = (node, cb) -> callReadMetadata(node, cb)

  callReadMetadata = (node, callback) ->
    val = {type: $('#metadataArea #selected_directory').val(), name: node.id}
    action = "read"
    method = "post"
    options = get_options(action, method, val)
    executeAjax(options, processReadSuccess, displayError, callback)

  processReadSuccess = (json, callback) ->
    currentId = json.fullName
    nodeGrids[currentId] = json.grid
    createGrid("#metadataArea #sample", json.grid)
    callback(json.tree)

  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    if grids[elementId]
      table = grids[elementId]
      table.destroy()

    header = get_columns(json)
    records = get_rows(json)
    columns_option = get_columns_option(json)

    hotSettings = {
        data: records,
        height: 500;
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columns_option,
        contextMenu: false,
        startRows: 0,
        afterChange: (source, changes) -> detect_check(source, changes)
    }

    grids[elementId] = new Handsontable(hotElement, hotSettings)

  detect_check = (source, changes) ->
    if changes == 'edit'
      row_index = source[0][0]
      checked = source[0][3]
      if checked
        selectedRowData[row_index] = grids["#metadataArea #grid"].getDataAtRow(row_index)
      else
        delete selectedRowData[row_index]


  get_columns = (json) ->
    if !json?
      null
    else
      json.columns

  get_rows = (json) ->
    if !json?
      null
    else
      json.rows

  get_executed_soql = (json) ->
    if !json?
      null
    else
      result.soql

  get_columns_option = (json) ->
    if !json?
      [[]]
    else
      json.column_options

  $("#metadataArea #tabArea").tabs()

  createGrid("#metadataArea #grid")
  createGrid("#metadataArea #sample")

  #$(".sub-btn").hide()

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