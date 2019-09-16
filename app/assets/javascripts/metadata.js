/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const coordinates = function() {
  
  let selectedRecords = {};
  let grid = null;
  const defaultDataType = "";
  const defaultContentType = null;
  let selectedFullNames = {};
  let selectedNode = null;
  let fieldNames = null;
  let fieldTypes = null;
  let deployId = null;
  let retrieveId = null;
  const checkInterval = 2000;
  let checkCount = 0;

  const disableButtons = function() {
    $("#updateMetadataBtn").prop("disabled", true);
    $("#deleteMetadataBtn").prop("disabled", true);
    $("#readMetadaBtn").prop("disabled", true);
    $("#collapseMetadataTree").prop("disabled", true);
    return $("#retrieveMetadataBtn").prop("disabled", true);
  };

  const getSelectedMetadata = () => $('#metadataArea #selected_directory').val();

  const getSelectedRecords = () => JSON.stringify(Object.values(selectedRecords));

  const getSelectedFullNames = () => JSON.stringify(Object.keys(selectedFullNames));

  //------------------------------------------------
  // list metadata
  //------------------------------------------------
  $("#metadataArea #executListMetadataBtn").on("click", function(e) {
    e.preventDefault();
    return listMetadate();
  });

  var listMetadate = function() {
    hideMessageArea();
    clearResults();
    const val = {selected_directory: getSelectedMetadata()};
    const action = $('#metadataArea .metadata-form').attr('action');
    const method = $('#metadataArea .metadata-form').attr('method');
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
    const callbacks = $.getAjaxCallbacks(processListSuccessResult, processListError, null);
    return $.executeAjax(options, callbacks);
  };

  var clearResults = function() {
    if ($.isAjaxBusy()) {
      $.abortAjax();
    }

    createGrid("#metadataArea #metadataGrid");
    $('#metadataArea #editMetadataTree').jstree(true).settings.core.data = null;
    $('#metadataArea #editMetadataTree').jstree(true).refresh();
    selectedRecords = {};
    fieldNames = null;
    fieldTypes = null;
    selectedFullNames = {};
    return selectedNode = null;
  };

  var processListError = function(json) {
    disableButtons();
    return displayError(json);
  };

  var processListSuccessResult = function(json) {
    hideMessageArea();
    refreshTree(json.tree);
    changeButtonStyles(json.crud_info);
    return createGrid("#metadataArea #metadataGrid", json.list_grid);
  };

  var changeButtonStyles = function(json) {
    $("#updateMetadataBtn").prop("disabled", !json.api_updatable);
    $("#deleteMetadataBtn").prop("disabled", !json.api_deletable);
    $("#readMetadaBtn").prop("disabled", !json.api_readable);
    $("#collapseMetadataTree").prop("disabled", !json.api_readable);
    return $("#retrieveMetadataBtn").prop("disabled", false);
  };

  var refreshTree = function(json) {
    $('#metadataArea #editMetadataTree').jstree(true).settings.core.data = json;
    $('#metadataArea #editMetadataTree').jstree(true).refresh();
    return $('#metadataArea #editMetadataTree').jstree(true).settings.core.data = (node, callback) => callReadMetadata(node, callback);
  };

  //------------------------------------------------
  // Read metadata
  //------------------------------------------------
  var callReadMetadata = function(node, callback) {
    const val = {crud_type: "read", metadata_type: getSelectedMetadata(), name: node.id};
    const action = $("#readMetadataBtn").attr("action");
    const method = "POST";
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false);
    const callbacks = $.getAjaxCallbacks(processReadSuccess, processReadError, callback);
    return $.executeAjax(options, callbacks);
  };

  var processReadSuccess = function(json, callback) {
    hideMessageArea();
    return callback(json.tree);
  };

  var processReadError = function(json, callback) {
    callback([]);
    return displayError(json);
  };

  //------------------------------------------------
  // retrieve
  //------------------------------------------------
  $("#metadataArea #retrieveMetadataBtn").on("click", function(e) {
    if (retrieveId) {
      return false;
    }
    
    e.preventDefault();
    checkCount = 0;
    
    const selected_type = getSelectedMetadata();
    const selected_records = getSelectedRecords();
    const val = {selected_type, selected_records};
    const action = $("#metadataArea #retrieveMetadataBtn").attr('action');
    const method ="POST";
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
    const callbacks = $.getAjaxCallbacks(checkRetrieveStatus, displayError, null);
    return $.executeAjax(options, callbacks);
  });
    
  var checkRetrieveStatus = function(json) {
    if (json.done) {
      return retrieveDone(json);
    } else {
      retrieveId = json.id;
      checkCount++;
      sleep(checkInterval * checkCount);      
      const val = {id: retrieveId};
      const action = "metadata/retrieve_check";
      const method = "POST";
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      const callbacks = $.getAjaxCallbacks(checkRetrieveStatus, displayError, null);
      return $.executeAjax(options, callbacks);
    }
  };

  var sleep = function(waitMsec) {
    const startMsec = new Date();
    while ((new Date - startMsec) < waitMsec) {
      return;
    }
  };

  var retrieveDone = function(json) {
    retrieveId = null;
    const url = "metadata/retrieve_result";
    const method = "post";
    const options = $.getAjaxDownloadOptions(url, method, null, downloadDone, downloadFail, function() {});
    return $.ajaxDownload(options);
  };
    
  var downloadDone = url => hideMessageArea();
  
  var downloadFail = (response, url, error) => displayError($.parseJSON(response));

  //------------------------------------------------
  // deploy
  //------------------------------------------------
  $("#metadataArea #deployMetadataBtn").on("click", function(e) {
    if (deployId) {
      return false;
    }

    e.preventDefault();
    
    const file = $('#metadataZipFile')[0].files[0];

    if (file instanceof Blob) {
      $('#metadataArea #deployMetadataResultTree').jstree(true).settings.core.data = null;
      $('#metadataArea #deployMetadataResultTree').jstree(true).refresh();
      return getBase64(file);
    } else {
      return displayError( {error: "Select a zip file to deploy"} );
    }
  });


  var getBase64 = function(file) {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    return reader.onload = () => uploadFile(reader.result.replace(new RegExp("data:.*/.*;base64,","g"), ""));
  };

  var uploadFile = function(file) {

    checkCount = 0;
    const deploy_options = {};

    $("#metadataArea #deployMetadataOptions input[type=checkbox]").each(function() {
      const key = $(this).val();
      const value = $(this).prop("checked");
      return deploy_options[key] = value;
    });

    const val = {options: JSON.stringify(deploy_options), zip_file: file};
    const action = $("#metadataArea #deployMetadataBtn").attr('action');
    const method = "POST";
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
    const callbacks = $.getAjaxCallbacks(checkDeployStatus, displayError, null);
    return $.executeAjax(options, callbacks);
  };

  var checkDeployStatus = function(json) {
    if (json.done) {
      return deployDone(json);
    } else {
      deployId = json.id;
      checkCount++;
      sleep(checkInterval * checkCount);      
      const val = {id: deployId};
      const action = "metadata/deploy_check";
      const method = "POST";
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      const callbacks = $.getAjaxCallbacks(checkDeployStatus, displayError, null);
      return $.executeAjax(options, callbacks);
    }
  };

  var deployDone = function(json) {
    deployId = null;
    $('#metadataArea #deployMetadataResultTree').jstree(true).settings.core.data = json.result;
    $('#metadataArea #deployMetadataResultTree').jstree(true).refresh();
    return hideMessageArea();
  };

  //------------------------------------------------
  // edit/update
  //------------------------------------------------
  $("#updateMetadataBtn").on("click", function(e) {
    e.preventDefault();
    if (window.confirm("Update Metadata?")) {
      const val = {crud_type: "update", metadata_type: getSelectedMetadata(), full_names: getSelectedFullNames()};
      const action = $("#metadataArea #updateMetadataBtn").attr("action");
      const method = "POST";
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      const callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null);
      return $.executeAjax(options, callbacks);
    }
  });

  $("#metadataArea #editMetadataTree").on('select_node.jstree', (e, data) => selectedNode = data.node);

  $("#metadataArea #editMetadataTree").on('rename_node.jstree', function(e, data) {
    if (data.text === data.old) {
      return;
    }

    const val = {
           metadata_type: getSelectedMetadata(),
           node_id: data.node.id,
           full_name: data.node.li_attr.full_name,
           path: data.node.li_attr.path,
           new_value: data.text,
           old_value: data.old,
           data_type: data.node.li_attr.data_type
          };
    const action = $("#metadataArea #editMetadataTree").attr("action");
    const method = "POST";
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false);
    const callbacks = $.getAjaxCallbacks(editComplete, undoEdit, null);
    return $.executeAjax(options, callbacks);
  });

  $("#readMetadaBtn").on("click", function(e) {
    if (selectedNode) {
      return $("#metadataArea #editMetadataTree").jstree(true).open_all(selectedNode);
    }
  });

  $("#collapseMetadataTree").on("click", function(e) {
    if (selectedNode) {
      return $("#metadataArea #editMetadataTree").jstree(true).close_all(selectedNode);
    }
  });

  var editComplete = function(json) {
    const fullName = json.full_name;
    selectedFullNames[fullName] = fullName;
    return hideMessageArea();
  };
    
  var undoEdit = function(json) {
    const node = $("#metadataArea #editMetadataTree").jstree(true).get_node(json.node_id);
    $("#metadataArea #editMetadataTree").jstree(true).edit(node, json.old_text);
    return displayError(json);
  };

  const treeChecker = function(operation, node, node_parent, node_position, more) {    
    if ((operation === 'edit') && !node.li_attr.editable) {
        return false;
      }
  };

  //------------------------------------------------
  // Delete metadata
  //------------------------------------------------
  $("#deleteMetadataBtn").on("click", function(e) {
    e.preventDefault();
    if (window.confirm("Delete Metadata?")) {
      const val = {crud_type: "delete", metadata_type: getSelectedMetadata(), selected_records: getSelectedRecords()};
      const action = $("#metadataArea #deleteMetadataBtn").attr("action");
      const method = "POST";
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      const callbacks = $.getAjaxCallbacks(saveSuccess, displayError, null);
      return $.executeAjax(options, callbacks);
    }
  });

  //------------------------------------------------
  // Crud success/error
  //------------------------------------------------
  var saveSuccess = function(json) {
    hideMessageArea();
    alert(json.message);
    if (json.refresh_required) {
      return listMetadate();
    }
  };

  //------------------------------------------------
  // message
  //------------------------------------------------
  var displayError = function(json) {
    retrieveId = null;
    deployId = null;
    $("#metadataArea .messageArea").html(json.error);
    return $("#metadataArea .messageArea").show();
  };
  
  var hideMessageArea = function() {
    $("#metadataArea .messageArea").empty();
    return $("#metadataArea .messageArea").hide();
  };

  //------------------------------------------------
  // Events on table
  //------------------------------------------------
  const onAfterChange = function(source, changes) {
    if (changes !== 'edit') {
      return;
    }

    const rowIndex = source[0][0];
    const checked = source[0][3];

    if (checked) {
        return selectedRecords[rowIndex] = grid.getDataAtRow(rowIndex);
    } else {
      return delete selectedRecords[rowIndex];
    }
  };

  //------------------------------------------------
  // HandsonTable
  //------------------------------------------------
  var createGrid = function(elementId, json = null) {   
    const hotElement = document.querySelector(elementId);

    if (grid) {
      grid.destroy();
    }

    const header = getColumns(json);
    const records = getRows(json);
    const columnsOption = getColumnsOption(json);
    const contextMenu = getContextMenuOption(json);

    const hotSettings = {
        data: records,
        height: 500,
        stretchH: 'all',
        autoWrapRow: true,
        allowRemoveColumn: false,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columnsOption,
        startRows: 0,
        fillHandle: {autoInsertRow: false},
        fragmentSelection: true,
        columnSorting: true,
        afterChange(source, changes) { return onAfterChange(source, changes); },
        licenseKey: 'non-commercial-and-evaluation'
    };

    const hot = new Handsontable(hotElement, hotSettings);
    hot.updateSettings({afterColumnSort() {
      return hot.render();
    }
    });

    return grid = hot;
  };

  var getColumns = function(json) {
    if (!json) {
      return null;
    } else {
      return json.columns;
    }
  };

  var getRows = function(json) {
    if (!json) {
      return null;
    } else {
      return json.rows;
    }
  };

  var getColumnsOption = function(json) {
    if (!json) {
      return [[]];
    } else if (json.column_options) {
      return json.column_options;
    } else { 
      return null;
    }
  };

  var getContextMenuOption = function(json) {
    if (json && json.context_menu) {
      return ["row_above", "row_below", "---------", "remove_row", "---------", "undo", "redo", "---------", "alignment"];
    } else {
      return false;
    }
  };

  //------------------------------------------------
  // page load actions
  //------------------------------------------------
  disableButtons();

  $("#metadataArea .tabArea").tabs();
  createGrid("#metadataArea #metadataGrid");

  $('#metadataArea #editMetadataTree').jstree({
    
    'core' : {
      'check_callback'(operation, node, node_parent, node_position, more) { return treeChecker(operation, node, node_parent, node_position, more); },
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    },
    "plugins": ["dropdown"]
  });

  return $('#metadataArea #deployMetadataResultTree').jstree({
    
    'core' : {
      'data' : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  });
};

$(document).ready(coordinates);
$(document).on('page:load', coordinates);
