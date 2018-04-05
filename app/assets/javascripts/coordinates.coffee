coordinates = ->
  
  selectedTabId = 1

  $('.execute-soql').on 'click', (e) ->
    e.preventDefault()
    selectedTabId =  $("div#tabArea").tabs('option', 'active') + 1
    getCoordinatesInRange()

  $(document).on 'click', 'span', (e) ->
    e.preventDefault()
    tabContainerDiv=$(this).closest(".ui-tabs").attr("id")
    tabCount = $("#" + tabContainerDiv).find(".ui-closable-tab").length
    alert(tabCount)
    if tabCount <= 1
      return

    if window.confirm("Close this tab?")
      panelId = $( this ).closest( "li" ).remove().attr( "aria-controls" )
      $( "#" + panelId ).remove();
      $("#" + tabContainerDiv).tabs("refresh")


  $('#add-tab').on 'click', (e) ->
    e.preventDefault()

    new_tab_index = $("div#tabArea ul li").length
    new_tab_id = new_tab_index + 1

    $("div#tabArea ul").append(
      "<li><a href=\"#tab" + new_tab_id + "\">Grid" + new_tab_id + "</a>" +
      "<span class=\"ui-icon ui-icon-close ui-closable-tab\"></span>" +
      "</li>"
    )

    $("div#tabArea").append(
      "<div id=\"tab" + new_tab_id + "\" class=\"resultTab\">" +
      "<div id=\"soql" + new_tab_id + "\" class=\"resultSoql\"></div>" +
      "<div id=\"grid" + new_tab_id + "\" class=\"resultGrid\"></div>" +
      "</div>"
    )
    
    selectedTabId =  new_tab_id

    createGrid()
    
    $("div#tabArea").tabs("refresh")

    $("div#tabArea").tabs({ active: new_tab_index });

  getCoordinatesInRange = ->
    post_data = {soql: $('#input_soql').val()}

    jqXHR = $.ajax({
      async: true
      url: $('.execute-form').attr('action')
      type: $('.execute-form').attr('method')
      data: post_data
      dataType: 'json'
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      console.log { done: stat, data: data, xhr: xhr }
      $("#messageArea").empty()
      $("#messageArea").hide()
      createGrid(xhr.responseText)

    jqXHR.fail (xhr, stat, err) ->
      console.log { fail: stat, error: err, xhr: xhr }
      displayError(xhr.responseText)

    jqXHR.always (res1, stat, res2) ->
      console.log { always: stat, res1: res1, res2: res2 }
      #alert 'Ajax Finished!' if stat is 'success'

  displayError = (error) ->
    $("#messageArea").html($.parseJSON(error).error)
    $("#messageArea").show()

  createGrid = (result = null) ->   
    hotElement = document.querySelector("#grid" + selectedTabId)

    table = new Handsontable(hotElement)
    table.destroy()

    parsedResult = $.parseJSON(result)
    $("#soql" + selectedTabId).html(get_executed_soql(parsedResult))
    header = get_columns(parsedResult)
    records = get_rows(parsedResult)
    columns_option = get_columns_option(parsedResult)

    hotSettings = {
        data: records,
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
      [[]]
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
  
  $("div#tabArea").tabs()

  createGrid()

$(document).ready(coordinates)
$(document).on('page:load', coordinates)