coordinates = ->
  
  selectedTabId = 1
  selectedRowData = {}
  grids = {}
  jqXHR = null
  
  get_options = (action, method, data, datatype, doAsync = true) ->
    {
      "async" : doAsync,
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }

  $(".execute-metadata").on "click", (e) ->
    e.preventDefault()
    clearResults()
    val = {selected_directory: $('#selected_directory').val()}
    action = $('.metadata-form').attr('action')
    method = $('.metadata-form').attr('method')
    options = get_options(action, method, val)
    executeAjax(options, processSuccessResult, displayError)

  $("#read-btn").on "click", (e) ->
    e.preventDefault()
    
    val = {data: selectedRowData}
    action = "read"
    method = "post"
    options = get_options(action, method, val)
    executeAjax(options, processSuccess, displayError)

  processSuccess = (json) ->
    createGrid("#sample", json.grid)
    $('#tree').jstree(true).open_node(json.node)

  clearResults = () ->
    selectedRowData = {}
    createGrid("#grid")
    createGrid("#sample")
    $('#tree').jstree(true).settings.core.data = null
    $('#tree').jstree(true).refresh()

  executeAjax = (options, doneCallback, errorCallback) ->

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
      $("#messageArea").empty()
      $("#messageArea").hide()
      doneCallback($.parseJSON(xhr.responseText))

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      alert(err)
      errorCallback($.parseJSON(xhr.responseText))

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  displayError = (json) ->
    $('#loading').hide()
    $("#messageArea").html(json.error)
    $("#messageArea").show()
  
  processSuccessResult = (json) ->
    refreshTree(json.tree)
    createGrid("#grid", json.grid)
    
  getUrl = () ->
    "meta_refresh?selected_metadata=" + $('#selected_directory').val()

  refreshTree = (json) ->
    $('#tree').jstree(true).settings.core.data = json
    $('#tree').jstree(true).refresh()
    $('#tree').jstree(true).settings.core.data = { 'url' : getUrl(), 'data' : (node) -> {"id":node.id}}

  createGrid = (id, json = null) ->   
    hotElement = document.querySelector(id)

    if grids[id]
      table = grids[id]
      table.destroy()

    header = get_columns(json)
    records = get_rows(json)
    columns_option = get_columns_option(json)

    hotSettings = {
        data: records,
        height: 500;
        preventOverflow: 'horizontal',
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

    grids[id] = new Handsontable(hotElement, hotSettings)

  detect_check = (source, changes) ->
    if changes == 'edit'
      row_index = source[0][0]
      checked = source[0][3]
      if checked
        selectedRowData[row_index] = grids["#grid"].getDataAtRow(row_index)
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

  $("div#tabArea").tabs()

  createGrid("#grid")
  createGrid("#sample")

  #$(".sub-btn").hide()

  $('#tree').jstree({
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