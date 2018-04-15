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

  #$('#selected_directory').on 'change', (e) ->
    #e.stopPropagation()
    #e.preventDefault()
 
    #val = {directory_name: e.target.value}
    #action = "change"
    #method = "get"
    #options = get_options("meta_change", "get", val, "text")
    #executeAjax(options, refreshSelectOptions, displayError)



  refreshTree = (result) ->
    $('#tree').jstree(true).settings.core.data = $.parseJSON(result)
    $('#tree').jstree(true).refresh()
    $(".exp-btn").prop("disabled", false)

  $(".execute-metadata").on "click", (e) ->
    e.preventDefault()
    val = {selected_directory: $('#selected_directory').val()}
    action = $('.metadata-form').attr('action')
    method = $('.metadata-form').attr('method')
    options = get_options(action, method, val)
    executeAjax(options, refreshTree, displayError)

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

  $('#tree').jstree({
    'core' : {
      'check_callback' : true,
      'data' : [ # 画面に表示する仮の初期データ
        { 'id' : '1', 'parent' : '#', 'text' : 'Root node 1', 'state' : { 'opened' : true } },
        { 'id' : '2', 'parent' : '1', 'text' : 'Child node 1' },
        { 'id' : '3', 'parent' : '1', 'text' : 'Child node 2' },
        { 'id' : '4', 'parent' : '#', 'text' : 'Root node 2' }
      ]
      "themes": {"icons":false}
    }
  })

  $(".exp-btn").prop("disabled", true)

$(document).ready(coordinates)
$(document).on('page:load', coordinates)