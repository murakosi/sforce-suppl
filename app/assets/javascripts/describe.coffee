
describe = ->
  
  defaultDataType = ""  
  defaultContentType = null
  sObjects = {}
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
      return false
  
  $('.sobjectTypeCheckBox').on 'change', (e) ->
    e.stopPropagation()
    e.preventDefault()

    disableOptions()
    val = {object_type: e.target.value}
    action = $('#filterSObjectList').attr('action')
    method = $('#filterSObjectList').attr('method')
    options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false)
    callbacks = $.getAjaxCallbacks(refreshSelectOptions, displayError, null)
    $.executeAjax(options, callbacks, true)

  disableOptions = () ->
    $("#describeArea .sobject-select-list").prop("disabled", true)
    $("#sobjectTypeCheckBox_all").prop("disabled", true);
    $("#sobjectTypeCheckBox_standard").prop("disabled", true);
    $("#sobjectTypeCheckBox_custom").prop("disabled", true);

  enableOptions = () ->
    $("#describeArea .sobject-select-list").prop("disabled", false)
    $("#sobjectTypeCheckBox_all").prop("disabled", false);
    $("#sobjectTypeCheckBox_standard").prop("disabled", false);
    $("#sobjectTypeCheckBox_custom").prop("disabled", false);

  #------------------------------------------------
  # describe
  #------------------------------------------------
  $('#executeDescribeBtn').on 'click', (e) ->
    e.preventDefault()
    executeDescribe()

  executeDescribe = () ->
    if $.isAjaxBusy()
      return false

    selectedTabId = getActiveTabElementId()
    sobject = $('#describeArea #sobject_selection').val()
    if sobject
      disableOptions()
      val = {selected_sobject: sobject}
      action = $('#executeDescribeBtn').attr('action')
      method = $('#executeDescribeBtn').attr('method')
      options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType)
      callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null)
      $.executeAjax(options, callbacks)

  #------------------------------------------------
  # CSV Download
  #------------------------------------------------
  $('#describeArea .export-btn').on 'click', (e) ->
    elementId = getActiveGridElementId()
    sobjectName = sObjects[elementId]
    if sobjectName
      hotElement = getActiveGrid()
      hotElement.getPlugin('exportFile').downloadFile('csv', {
        bom: false,
        columnDelimiter: ',',
        columnHeaders: true,
        exportHiddenColumns: false,
        exportHiddenRows: false,
        fileExtension: 'csv',
        filename: sobjectName,
        mimeType: 'text/csv',
        rowDelimiter: '\r\n',
        rowHeaders: false
      })

  #------------------------------------------------
  # callbacks
  #------------------------------------------------  
  displayError = (json) ->
    $("#describeArea .messageArea").html(json.error)
    $("#describeArea .messageArea").show()
    enableOptions()
  
  hideMessageArea = () ->
    $("#describeArea .messageArea").empty()
    $("#describeArea .messageArea").hide()
    enableOptions()

  processSuccessResult = (json) ->
    hideMessageArea()
    $("#describeArea #overview" + selectedTabId).html(getExecutedMethod(json))
    elementId = "#describeArea #describeGrid" + selectedTabId
    sObjects[elementId] = json.sobject_name
    createGrid(elementId, json)

  refreshSelectOptions = (result) ->
    $('#describeArea .sobject-select-list').html(result)
    $('#describeArea .sobject-select-list').select2({
        dropdownAutoWidth : true,
        width: 'element',
        containerCssClass: ':all:',
        placeholder: "Select an sObject",
        allowClear: true
      })
    enableOptions()

  #------------------------------------------------
  # Active grid
  #------------------------------------------------
  getActiveTabElementId = () ->
    $("#describeArea .tabArea .ui-tabs-panel:visible").attr("tabId")

  getActiveGridElementId = () ->
    tabId = $("#describeArea .tabArea .ui-tabs-panel:visible").attr("tabId")
    "#describeArea #describeGrid" + tabId
    
  getActiveGrid = () ->
    elementId = getActiveGridElementId()
    grids[elementId]

  #------------------------------------------------
  # Create tab
  #------------------------------------------------
  $("#describeArea .add-tab-btn").on 'click', (e) ->
    createTab()

  $(document).on 'click', '#describeArea .ui-closable-tab', (e) ->
    e.preventDefault()

    if $("#describeArea .tabArea ul li").length <= 2
      return

    panelId = $(this).closest("#describeArea li").remove().attr("aria-controls")
    $("#describeArea #" + panelId ).remove();
    $("#describeArea .tabArea").tabs("refresh")

  $('#describeArea #add-tab').on 'click', (e) ->
    e.preventDefault()
    createTab()
  
  createTab = () ->
    currentTabIndex = currentTabIndex + 1
    newTabId = currentTabIndex

    $("#describeArea .tabArea ul li:last").before(
      "<li class=\"noselect\"><a href=\"#describeTab" + newTabId + "\">Grid" + newTabId + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    overviewArea = '<div id="overview' + newTabId + '" class="resultSoql" tabId="' + newTabId + '"></div>'    
    
    $("#describeArea .tabArea").append(
      "<div id=\"describeTab" + newTabId + "\" class=\"resultTab\" tabId=\"" + newTabId + "\">" +
      overviewArea +
      "<div id=\"describeGrid" + newTabId + "\" class=\"resultGrid\" tabId=\"" + newTabId + "\"></div>" +
      "</div>"
    )
    
    createGrid("#describeArea #describeGrid" + newTabId)
    
    $("#describeArea .tabArea").tabs("refresh")

    setSortableAttribute()
    
    newTabIndex = $("#describeArea .tabArea ul li").length - 2
    selectedTabId = newTabIndex
    $("#describeArea .tabArea").tabs({ active: newTabIndex});

  setSortableAttribute = () ->
    if $("#describeTabs li" ).length > 2
      $("#describeTabs").sortable("enable")
    else
      $("#describeTabs").sortable('disable')

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
    height = if json then 500 else 0

    hotSettings = {
        data: records,
        #height: height,
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

  if $("#describeArea").length
    $("#describeArea .tabArea").tabs()
    $("#describeTabs").sortable({items: 'li:not(.add-tab-li)', delay: 150});
    createTab()

$(document).ready(describe)
$(document).on('page:load', describe)
