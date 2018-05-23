
coordinates = ->
  
  jqXHR = null
  defaultDataType = "text"  

  getAjaxOptions = (action, method, data, datatype) ->
    {
      "action": action,
      "method": method,
      "data": data,
      "datatype": datatype
    }

  $('.sobjectTypeCheckBox').on 'click', (e) ->
      if jqXHR
        e.preventDefault
        return false
  
  $('.sobjectTypeCheckBox').on 'change', (e) ->

    e.stopPropagation()
    e.preventDefault()

    val = {object_type: e.target.value}
    action = $('#filterSObjectList').attr('action')
    method = $('#filterSObjectList').attr('method')
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, refreshSelectOptions, displayError)

  $('#executeDescribe').on 'click', (e) ->
    e.preventDefault()

    val = {selected_sobject: $('#describeArea #selected_sobject').val()}
    action = $('#executeDescribe').attr('action')
    method = $('#executeDescribe').attr('method')
    options = getAjaxOptions(action, method, val, defaultDataType)
    executeAjax(options, processSuccessResult, displayError)

  $("#describeArea .exp-btn").on "click", (e) ->
    $("#describeArea #format").val($(this).attr("format"))
    $("#describeArea #selected_sobject").val($('#describeArea #selected_sobject').val())

  executeAjax = (options, doneCallback, errorCallback) ->

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

  processSuccessResult = (result) ->
    json = $.parseJSON(result)
    $("#describeArea #method").html(getExecutedMethod(json))
    createGrid("#describeArea #grid", json)

  refreshSelectOptions = (result) ->
    $('#sobjectList').html(result)
    
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

$(document).ready(coordinates)
$(document).on('page:load', coordinates)