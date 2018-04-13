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

  $('.chk').on 'change', (e) ->
    e.stopPropagation()
    e.preventDefault()
 
    val = {object_type: e.target.value}
    action = "change"
    method = "get"
    options = get_options("change", "get", val, "text")
    executeAjax(options, refreshSelectOptions, displayError)

  refreshSelectOptions = (result) ->
    $('#object_list').html(result)

  $('.execute-describe').on 'click', (e) ->
    e.preventDefault()
    selectedTabId =  $("div#tabArea").tabs('option', 'active') + 1

    val = {selected_sobject: $('#selected_sobject').val()}
    action = $('.describe-form').attr('action')
    method = $('.describe-form').attr('method')
    options = get_options(action, method, val)
    executeAjax(options, createGrid, displayError)

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
      #alert 'Ajax Finished!' if stat is 'success'

  displayError = (error) ->
    $("#messageArea").html($.parseJSON(error).error)
    $("#messageArea").show()
    $(".exp-btn").prop("disabled", true);

  createGrid = (result = null) ->   
    hotElement = document.querySelector("#grid" + selectedTabId)

    table = new Handsontable(hotElement)
    table.destroy()

    parsedResult = $.parseJSON(result)
    $("#method" + selectedTabId).html(get_executed_method(parsedResult))
    header = get_columns(parsedResult)
    records = get_rows(parsedResult)
    columns_option = get_columns_option(parsedResult)

    hotSettings = {
        data: records,
        width: get_grid_width(parsedResult),
        height: 500;
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columns_option,
        contextMenu: false,
        readOnly: true,
        startRows: 0
    }

    table = new Handsontable(hotElement, hotSettings)

    $(".exp-btn").prop("disabled", false);

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

  get_executed_method = (result) ->
    if !result?
      null
    else
      result.method

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

  $(".exp-btn").prop("disabled", true)

$(document).ready(coordinates)
$(document).on('page:load', coordinates)