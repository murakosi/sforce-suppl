coordinates = ->

  selectedTabId = 0
  $("div#tabs").tabs()

  $('.execute-soql').on 'click', (e) ->
    e.preventDefault()
    selectedTabId =  $("div#tabs").tabs('option', 'active') + 1
    $("#errorMessage").empty()
    $("#errorMessage").hide()
    getCoordinatesInRange()

  getCoordinatesInRange = ->
    post_data = {soql: $('#input_soql').val()}

    jqXHR = $.ajax({
      async: true
      url: $('.form-inline').attr('action')
      type: $('.form-inline').attr('method')
      data: post_data
      dataType: 'json'
      cache: false
    })

    jqXHR.done (data, stat, xhr) ->
      console.log { done: stat, data: data, xhr: xhr }
      alert "done"
      createGrid(xhr.responseText)

    jqXHR.fail (xhr, stat, err) ->
      console.log { fail: stat, error: err, xhr: xhr }
      alert xhr.responseText
      displayError(xhr.responseText)

    jqXHR.always (res1, stat, res2) ->
      console.log { always: stat, res1: res1, res2: res2 }
      alert 'Ajax Finished!' if stat is 'success'

  displayError = (error) ->
    #$("#errorMessage").html(JSON.parse(error).error)
    $("#errorMessage").html($.parseJSON(error).error)
    $("#errorMessage").show()

  createGrid = (result = null) ->
    hotElement = document.querySelector("#myGrid" + selectedTabId)
    table = new Handsontable(hotElement)
    table.destroy()
    
    parsedResult = $.parseJSON(result)
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
      Object.keys(result[0])

  get_rows = (result) ->
    if !result?
      null
    else
      Object.values(result)

  get_columns_option = (result) ->
    if !result?
      [[]]
    else
      null

  $('#add-tab').on 'click', (e) ->
    e.preventDefault()
    
    new_tab_index = $("div#tabs ul li").length
    new_tab_id = new_tab_index + 1
    
    $("div#tabs ul").append(
      "<li><a href='#tab" + new_tab_id + "'>Grid " + new_tab_id + "</a></li>"
    )

    $("div#tabs").append(
      "<div id='tab" + new_tab_id + "' class='my-tab'>" +
      "<div id='myGrid" + new_tab_id + "' class='my-grid'></div>" +
      "</div>"
    )
    
    selectedTabId =  new_tab_id
    
    createGrid()
    
    $("div#tabs").tabs("refresh")

    $("div#tabs").tabs({ active: new_tab_index });

$(document).ready(coordinates)
#$(document).ready(tabutil)
$(document).on('page:load', coordinates)
#$(document).on('page:load', tabutil)