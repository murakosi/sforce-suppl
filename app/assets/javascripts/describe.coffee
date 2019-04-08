
coordinates = ->
  
  defaultDataType = ""  
  defaultContentType = null
  currentTable = null
  
  #------------------------------------------------
  # change custom/standard
  #------------------------------------------------
  $('.sobjectTypeCheckBox').on 'click', (e) ->
    if $.isAjaxBusy()
      e.preventDefault
      return false
  
  $('.sobjectTypeCheckBox').on 'change', (e) ->
    e.stopPropagation()
    e.preventDefault()

    val = {object_type: e.target.value}
    action = $('#filterSObjectList').attr('action')
    method = $('#filterSObjectList').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false)
    callbacks = $.getAjaxCallbacks(refreshSelectOptions, displayError, null)
    $.executeAjax(options, callbacks, true)

  #------------------------------------------------
  # describe
  #------------------------------------------------
  $('#executeDescribe').on 'click', (e) ->
    e.preventDefault()
    val = {selected_sobject: $('#describeArea #selected_sobject').val()}
    action = $('#executeDescribe').attr('action')
    method = $('#executeDescribe').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)

  #------------------------------------------------
  # export
  #------------------------------------------------
  $("#describeArea .exp-btn").on "click", (e) ->
    e.preventDefault()
    options = getDownloadOptions(this)
    $.ajaxDownload(options)

  getDownloadOptions = (target) ->
    url = $("#describeArea #exportForm").attr('action')
    method = $("#describeArea #exportForm").attr('method')
    selected_sobject = $('#describeArea #selected_sobject').val()
    dl_format = $(target).attr('dl_format')
    data = {dl_format: dl_format, selected_sobject: selected_sobject}
    $.getAjaxDownloadOptions(url, method, data, downloadDone, downloadFail, ->)

  #------------------------------------------------
  # callbacks
  #------------------------------------------------  
  displayError = (json) ->
    $("#describeArea #messageArea").html(json.error)
    $("#describeArea #messageArea").show()
  
  hideMessageArea = () ->
    $("#describeArea #messageArea").empty()
    $("#describeArea #messageArea").hide()

  processSuccessResult = (json) ->
    hideMessageArea()
    $("#describeArea #method").html(getExecutedMethod(json))
    createGrid("#describeArea #grid", json)

  refreshSelectOptions = (result) ->
    $('#sobjectList').html(result)
    $('.selectlist').select2({
      dropdownAutoWidth : true,
      width: 'resolve',
      containerCssClass: ':all:'
      })

  downloadDone = (url) ->
    hideMessageArea()
  
  downloadFail = (response, url, error) ->
    displayError(response)

  #------------------------------------------------
  # grid
  #------------------------------------------------ 
  createGrid = (elementId, json = null) ->   
    hotElement = document.querySelector(elementId)
    
    if currentTable
      currentTable.destroy()
      currentTable = null

    header = getColumns(json)
    records = getRows(json)
    columnsOption = getColumnsOption(json)

    hotSettings = {
        data: records,
        height: 500,
        stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        #columns: columnsOption,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        columnSorting: true,
        filters: true,
        dropdownMenu: ['filter_by_condition', 'filter_action_bar', 'filter_by_value'],
        licenseKey: 'non-commercial-and-evaluation'
    }

    currentTable = new Handsontable(hotElement, hotSettings)
    currentTable.updateSettings afterColumnSort: ->
      currentTable.render()
    #table.render()
    
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
    if json && json.column_options
      #json.column_options
      null
    else
      null

  $("#describeArea #tabArea").tabs()

  createGrid("#describeArea #grid")

$(document).ready(coordinates)
$(document).on('page:load', coordinates)
