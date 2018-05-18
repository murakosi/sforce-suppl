
coordinates = ->
  
  selectedTabId = 1
  jqXHR = null
  defaultDataType = "text"  

  getAjaxOptions = (action, method, data, datatype, doAsync = true) ->
    {
      "async" : doAsync,
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }

  $(".describe-form").on "ajax:success", (event) ->
    if event.originalEvent.detail
      alert(event.originalEvent.detail[0].errorMessage)

  $('.chk').on 'click', (e) ->
      if jqXHR
        e.preventDefault
        return false
  
  $('.chk').on 'change', (e) ->

    e.stopPropagation()
    e.preventDefault()

    val = {object_type: e.target.value}
    action = "change"
    method = "get"
    options = getAjaxOptions("desc_change", "get", val, defaultDataType)
    executeAjax(options, refreshSelectOptions, displayError)

  $('.execute-describe').on 'click', (e) ->
    e.preventDefault()

    val = {selected_sobject: $('#describeArea #selected_sobject').val()}
    action = $('.execute-describe').attr('action')
    method = $('.execute-describe').attr('method')
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, processSuccessResult, displayError)
    
  executeAjax = (options, doneCallback, errorCallback) ->

    if jqXHR
      return

    jqXHR = $.ajax({
      async: options.async
      url: options.action
      type: options.method
      data: options.data
      dataType: options.datatype
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      jqXHR = null
      console.log { done: stat, data: data, xhr: xhr }
      $("#describeArea #messageArea").empty()
      $("#describeArea #messageArea").hide()
      doneCallback(xhr.responseText)

    jqXHR.fail (xhr, stat, err) ->
      jqXHR = null
      console.log { fail: stat, error: err, xhr: xhr }
      alert(err)
      errorCallback(xhr.responseText)

    jqXHR.always (res1, stat, res2) ->
      jqXHR = null
      console.log { always: stat, res1: res1, res2: res2 }

  displayError = (result) ->
    json = $.parseJSON(result)
    $("#describeArea #messageArea").html(json.error)
    $("#describeArea #messageArea").show()
    $("#describeArea .exp-btn").prop("disabled", true);

  processSuccessResult = (result) ->
    json = $.parseJSON(result)
    $("#describeArea #method").html(getExecutedMethod(json))
    createGrid("#describeArea #grid", json)

  refreshSelectOptions = (result) ->
    $('#object_list').html(result)
    
  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)

    table = new Handsontable(hotElement)
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
        readOnly: true,
        startRows: 0
    }

    table = new Handsontable(hotElement, hotSettings)

    $("#describeArea .exp-btn").prop("disabled", false);

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

  getExecutedMethod = (json) ->
    if !json?
      null
    else
      json.method

  getColumnsOption = (json) ->
    if !json?
      [[]]
    else
      null

  $("#describeArea #tabArea").tabs()

  createGrid("#describeArea #grid")

  $("#describeArea .exp-btn").prop("disabled", true)

$(document).ready(coordinates)
$(document).on('page:load', coordinates)