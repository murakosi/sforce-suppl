# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
coordinates = ->
  
  selectedTabId = 1
  jqXHR = null

  get_options = (action, method, data, datatype) ->
    {
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }

  $(".execute-metadata").on "click", (e) ->
    e.preventDefault()
    $('#tree').jstree(true).settings.core.data = null
    $('#tree').jstree(true).refresh()
    $('#loading').show()

    val = {selected_directory: $('#selected_directory').val()}
    action = $('.metadata-form').attr('action')
    method = $('.metadata-form').attr('method')
    options = get_options(action, method, val)
    executeAjax(options, processSuccessResult, displayError)

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
      doneCallback(xhr.responseText)      

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      alert(err)
      errorCallback(xhr.responseText)

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  displayError = (error) ->
    $('#loading').hide()
    $("#messageArea").html($.parseJSON(error).error)
    $("#messageArea").show()
    $(".exp-btn").prop("disabled", true);
  
  processSuccessResult = (result) ->
    parsedResult = $.parseJSON(result)
    refreshTree(parsedResult.tree)
    createGrid(parsedResult.grid)
    
  refreshTree = (json) ->
    $('#loading').hide()
    $('#tree').jstree(true).settings.core.data = json
    $('#tree').jstree(true).refresh()
    $(".exp-btn").prop("disabled", false)

  createGrid = (json = null) ->   
    hotElement = document.querySelector("#grid")

    table = new Handsontable(hotElement)
    table.destroy()

    header = get_columns(json)
    records = get_rows(json)
    columns_option = get_columns_option(json)

    hotSettings = {
        data: records,
        width: get_grid_width(json),
        height: 500;
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columns_option,
        contextMenu: true,
        readOnly: true,
        startRows: 0
    }

    table = new Handsontable(hotElement, hotSettings)

  get_columns = (result) ->
    if !result?
      #[[]]
      null
    else
      result.columns

  get_rows = (result) ->
    if !result?
      null
    else
      result.rows

  get_executed_soql = (result) ->
    if !result?
      null
    else
      result.soql

  get_columns_option = (result) ->
    if !result?
      [[]]
    else
      null

  get_grid_width = (result) ->
    if !result?
      0
    else
      document.getElementById('tabArea').offsetWidth

  $("div#tabArea").tabs()

  createGrid()

  $('#tree').jstree({
    'core' : {
      'check_callback' : true,
      'data' : [ # 画面に表示する仮の初期データ
        { 'id' : '1', 'parent' : '#', 'text' : 'Root node 1', 'state' : { 'opened' : true } },
        { 'id' : '2', 'parent' : '1', 'text' : 'Child node 1' },
        { 'id' : '3', 'parent' : '1', 'text' : 'Child node 2' },
        { 'id' : '4', 'parent' : '#', 'text' : 'Root node 2' }
      ]
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  })

  $(".exp-btn").prop("disabled", true)
  $('#loading').hide()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)