
describe = ->
  
  defaultDataType = ""  
  defaultContentType = null
  currentTable = null
  grids = {}
  currentTabIndex = 0
  selectedTabId = null

  #------------------------------------------------
  # Shortcut keys
  #------------------------------------------------
  $(window).on 'keydown', (e) ->

    if $("#describeArea").is(":visible")

      if e.ctrlKey && (e.key == 'r' || e.keyCode == 13)
        e.preventDefault()       
        executeDescribe()
        return false

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
    executeDescribe()

  executeDescribe = () ->
    if $.isAjaxBusy()
      return false

    selectedTabId = getActiveTabElementId()
    val = {selected_sobject: $('#describeArea #selected_sobject').val()}
    action = $('#executeDescribe').attr('action')
    method = $('#executeDescribe').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
    callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
    $.executeAjax(options, callbacks)

  #------------------------------------------------
  # export
  #------------------------------------------------
  $("#describeArea #csv-expprt").on "click", (e) ->
    e.preventDefault()
    options = getDownloadOptions(this)
    $.ajaxDownload(options)

  getDownloadOptions = (target) ->
    url = $("#describeArea #exportForm").attr('action')
    method = $("#describeArea #exportForm").attr('method')
    selected_sobject = $('#describeArea #selected_sobject').val()
    data = {selected_sobject: selected_sobject}
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
    $("#describeArea #overview" + selectedTabId).html(getExecutedMethod(json))
    createGrid("#describeArea #describeGrid" + selectedTabId, json)

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
  # Active grid
  #------------------------------------------------
  getActiveTabElementId = () ->
    $("#describeArea #tabArea .ui-tabs-panel:visible").attr("tabId")

  getActiveGridElementId = () ->
    tabId = $("#describeArea #tabArea .ui-tabs-panel:visible").attr("tabId")
    "#describeArea #describeGrid" + tabId
    
  getActiveGrid = () ->
    elementId = getActiveGridElementId()
    grids[elementId]

  #------------------------------------------------
  # Create tab
  #------------------------------------------------
  $("#describeTabs").on "dblclick", (e) ->
    if e.target != this
      e.preventDefault()
      e.stopPropagation()
      return
    e.preventDefault()
    e.stopPropagation()
    $("#overview1").addClass("noselect")
    createTab()
    console.log(1)
    #$("#overview1").removeClass("noselect")

  $(".resultSoql").on "dblclick", (e) ->
    console.log(2)

  $(".resultSoql").on "click", (e) ->
    console.log(2)

  $(document).on 'click', '#describeArea .ui-closable-tab', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest("#describeArea .ui-tabs").attr("id")
    tabCount = $("#describeArea #" + tabContainerDiv).find(".ui-closable-tab").length

    if tabCount <= 1
      return

    if window.confirm("Close this tab?")
      panelId = $(this).closest("#describeArea li").remove().attr("aria-controls")
      $("#describeArea #" + panelId ).remove();
      $("#describeArea #" + tabContainerDiv).tabs("refresh")

  $('#describeArea #add-tab').on 'click', (e) ->
    e.preventDefault()
    createTab()
  
  createTab = () ->
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#describeArea #tabArea ul").append(
      "<li class=\"noselect\"><a href=\"#describeTab" + newTabId + "\">Grid" + newTabId + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    overviewArea = '<div id="overview' + newTabId + '" class="resultSoql" tabId="' + newTabId + '"></div>'    
    
    $("#describeArea #tabArea").append(
      "<div id=\"describeTab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\">" +
      overviewArea +
      "<div id=\"describeGrid" + newTabId + "\" class=\"resultGrid\" tabId=\"" + newTabId + "\"></div>" +
      "</div>"
    )
    
    createGrid("#describeArea #describeGrid" + newTabId)
    
    $("#describeArea #tabArea").tabs("refresh")
    
    newTabIndex = $("#describeArea #tabArea ul li").length - 1
    selectedTabId = newTabIndex
    $("#describeArea #tabArea").tabs({ active: newTabIndex});

  #------------------------------------------------
  # grid
  #------------------------------------------------ 
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
        height: 500,
        #stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        #columns: columnsOption,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        fragmentSelection: 'cell',
        columnSorting: true,
        filters: true,
        dropdownMenu: ['filter_action_bar', 'filter_by_value'],
        licenseKey: 'non-commercial-and-evaluation'
    }

    hot = new Handsontable(hotElement, hotSettings)
    hot.updateSettings afterColumnSort: ->
      hot.render()

    grids[elementId] = hot

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

  #createGrid("#describeArea #grid")
  createTab()

$(document).ready(describe)
$(document).on('page:load', describe)
