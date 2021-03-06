
const metadata = () => {
  
  let _currentMetadataType = null;
  let _selectedRecords = {};
  let _grid = null;
  let _selectedFullNames = {};
  let _selectedNode = null;
  let _deployId = null;
  let _retrieveId = null;
  let _checkCount = 0;  
  const CHECK_INTERVAL = 2000;
  const DEFAULT_DATA_TYPE = "";
  const DEFAULT_CONTENT_TYPE = null;
  const PLACEHOLDER = "Select a metadata type"
  const POST = "post";
  const DEPLOY_CHECK_PATH = "metadata/deploy_check";
  const RETRIEVE_CHECK_PATH = "metadata/retrieve_check";
  const RETRIEVE_RESULT_PATH = "metadata/retrieve_result";
  
  //------------------------------------------------
  // Handler
  //------------------------------------------------
  $(document).on("afterRefreshMetadataTypes", (e, param) => {
    refreshSelectOptions(param.result);
  });

  //------------------------------------------------
  // Shortcut keys
  //------------------------------------------------
  $(window).on("keydown", (e) => {

    if ($("#metadataArea").is(":visible")) {

      if (e.ctrlKey && (e.key === "r" || e.keyCode === 13)) {
        listMetadata();
        return false;
      }

      // escape
      if (e.keyCode === 27) {
        if ($.isAjaxBusy()) {
          $.abortAjax();
        }
        unlockForm();
      }
    }
  });

  //------------------------------------------------
  // List metadata
  //------------------------------------------------
  $("#metadataArea #executListMetadataBtn").on("click", (e) => {
    e.preventDefault();
    listMetadata();
  });

  const listMetadata = () => {
    if ($.isAjaxBusy()) {
      return false;
    }

    currentMetadataType = $("#metadataArea #selected_directory").val();
    if(!currentMetadataType){
      return false;
    }
    
    hideMessageArea();
    initializeResults();
    
    const val = {selected_directory: currentMetadataType};
    const action = $("#metadataArea .metadata-form").attr("action");
    const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
    const callbacks = $.getAjaxCallbacks(afterListMetadata, onListMetadataError, null);
    $.executeAjax(options, callbacks);
  };

  const onListMetadataError = (json) => {
    unlockForm();
    displayError(json);
  };

  const afterListMetadata = (json) => {
    _currentMetadataType = $("#metadataArea #selected_directory").val();
    unlockForm();
    refreshTree(json.tree);
    changeButtonStyles(json.crud_info);
    createGrid("#metadataArea #metadataGrid", json.metadata_list);
  };

  const initializeResults = () => {
    lockForm();
    disableButtons();
    createGrid("#metadataArea #metadataGrid");
    $("#metadataArea #editMetadataTree").jstree(true).settings.core.data = null;
    $("#metadataArea #editMetadataTree").jstree(true).refresh();
    _selectedRecords = {};
    _selectedFullNames = {};
    _selectedNode = null;
  };

  //------------------------------------------------
  // Read metadata
  //------------------------------------------------
  const readMetadata = (node, callback) => {
    hideMessageArea();
    const val = {crud_type: "read", metadata_type: _currentMetadataType, name: node.id};
    const action = $("#expandMetadataTree").attr("action");
    const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(afterReadSuccess, onReadError, callback);
    $.executeAjax(options, callbacks);
  };

  const afterReadSuccess = (json, callback) => {    
    callback(json.tree);
  };

  const onReadError = (json, callback) => {
    callback([]);
    displayError(json);
  };

  //------------------------------------------------
  // Delete metadata
  //------------------------------------------------
  $("#deleteMetadataBtn").on("click", (e) => {
    const selectedRecords = getSelectedRecords();

    if (!selectedRecords.length){
      return;
    }

    if (window.confirm("Delete Metadata?")) {
      hideMessageArea();
      const val = {crud_type: "delete", metadata_type: _currentMetadataType, selected_records: selectedRecords};
      const action = $("#metadataArea #deleteMetadataBtn").attr("action");
      const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
      const callbacks = $.getAjaxCallbacks(afterCrudSuccess, displayError, null);
      $.executeAjax(options, callbacks);
    }
  });

  //------------------------------------------------
  // Retrieve
  //------------------------------------------------
  $("#metadataArea #retrieveMetadataBtn").on("click", (e) => {
    if (_retrieveId) {
      return;
    }
    
    const selectedRecords = getSelectedRecords();

    if (!selectedRecords.length){
      return;
    }

    hideMessageArea();
    _checkCount = 0;
    const val = {selected_type: _currentMetadataType, selected_records: selectedRecords};
    const action = $("#metadataArea #retrieveMetadataBtn").attr("action");
    const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
    const callbacks = $.getAjaxCallbacks(checkRetrieveStatus, onRetrieveError, null);
    $.executeAjax(options, callbacks);
  });
    
  const checkRetrieveStatus = (json) => {
    if (json.done) {
      afterRetrieveSuccess(json);
    } else {
      _retrieveId = json.id;
      _checkCount++;
      sleep(CHECK_INTERVAL * _checkCount);      
      const val = {id: _retrieveId};
      const options = $.getAjaxOptions(RETRIEVE_CHECK_PATH, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
      const callbacks = $.getAjaxCallbacks(checkRetrieveStatus, onRetrieveError, null);
      $.executeAjax(options, callbacks);
    }
  };

  const afterRetrieveSuccess = (json) => {
    _retrieveId = null;
    const options = $.getAjaxDownloadOptions(RETRIEVE_RESULT_PATH, POST, null, (url) => {}, onDownloadError, () => {});
    $.ajaxDownload(options);
  };

  const onRetrieveError = (json) => {
    _retrieveId = null;
    displayError(json);
  }
  
  const onDownloadError = (response, url, error) => onRetrieveError($.parseJSON(response));

  //------------------------------------------------
  // Deploy
  //------------------------------------------------
  $("#metadataArea #deployMetadataBtn").on("click", (e) => {
    if (_deployId) {
      return false;
    }

    const file = $("#metadataZipFile")[0].files[0];

    if (file instanceof Blob) {
      hideMessageArea();
      $("#metadataArea #deployMetadataResultTree").jstree(true).settings.core.data = null;
      $("#metadataArea #deployMetadataResultTree").jstree(true).refresh();
      executeDeploy(file);
    } else {
      displayError( {error: "Select a zip file to deploy"} );
    }
  });

  const executeDeploy = (file) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => uploadFile(reader.result.replace(new RegExp("data:.*/.*;base64,","g"), ""));
  };

  const uploadFile = (file) => {

    _checkCount = 0;
    const deploy_options = {};

    $("#metadataArea #deployMetadataOptions input[type=checkbox]").each(function() {
      const key = $(this).val();
      const value = $(this).prop("checked");
      deploy_options[key] = value;
    });

    const val = {options: JSON.stringify(deploy_options), zip_file: file};
    const action = $("#metadataArea #deployMetadataBtn").attr("action");
    const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
    const callbacks = $.getAjaxCallbacks(checkDeployStatus, onDeployError, null);
    $.executeAjax(options, callbacks);
  };

  const checkDeployStatus = (json) => {
    if (json.done) {
      afterDeploySuccess(json);
    } else {
      _deployId = json.id;
      _checkCount++;
      sleep(CHECK_INTERVAL * _checkCount);      
      const val = {id: _deployId};
      const options = $.getAjaxOptions(DEPLOY_CHECK_PATH, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
      const callbacks = $.getAjaxCallbacks(checkDeployStatus, onDeployError, null);
      $.executeAjax(options, callbacks);
    }
  };

  const afterDeploySuccess = (json) => {
    _deployId = null;
    $("#metadataArea #deployMetadataResultTree").jstree(true).settings.core.data = json.result;
    $("#metadataArea #deployMetadataResultTree").jstree(true).refresh();    
  };

  const onDeployError = (json) => {
    _deployId = null;
    displayError(json);
  }

  //------------------------------------------------
  // Edit/Update
  //------------------------------------------------
  $("#updateMetadataBtn").on("click", (e) => {
    if (window.confirm("Update Metadata?")) {
      hideMessageArea();
      const val = {crud_type: "update", metadata_type: _currentMetadataType, full_names: getSelectedFullNames()};
      const action = $("#metadataArea #updateMetadataBtn").attr("action");
      const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
      const callbacks = $.getAjaxCallbacks(afterCrudSuccess, displayError, null);
      $.executeAjax(options, callbacks);
    }
  });

  $("#metadataArea #editMetadataTree").on("select_node.jstree", (e, data) => {
    _selectedNode = data.node;
  });

  $("#metadataArea #editMetadataTree").on("rename_node.jstree", (e, data) => {
    if (data.text === data.old) {
      return;
    }

    hideMessageArea();
    const val = {
           metadata_type: _currentMetadataType,
           node_id: data.node.id,
           full_name: data.node.li_attr.full_name,
           path: data.node.li_attr.path,
           new_value: data.text,
           old_value: data.old,
           data_type: data.node.li_attr.data_type
          };
    const action = $("#metadataArea #editMetadataTree").attr("action");
    const options = $.getAjaxOptions(action, POST, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(afterEditSuccess, undoEdit, null);
    $.executeAjax(options, callbacks);
  });

  $("#expandMetadataTree").on("click", (e) => {
    if (_selectedNode) {
      $("#metadataArea #editMetadataTree").jstree(true).open_all(_selectedNode);
    }
  });

  $("#collapseMetadataTree").on("click", (e) => {
    if (_selectedNode) {
      $("#metadataArea #editMetadataTree").jstree(true).close_all(_selectedNode);
    }
  });

  const afterEditSuccess = (json) => {
    _selectedFullNames[json.full_name] = true;    
  };
    
  const undoEdit = (json) => {
    const node = $("#metadataArea #editMetadataTree").jstree(true).get_node(json.node_id);
    $("#metadataArea #editMetadataTree").jstree(true).edit(node, json.old_text);
    displayError(json);
  };

  const validateEditTree = (operation, node, node_parent, node_position, more) => {
    if ((operation === "edit") && !node.li_attr.editable) {
      return false;
    }
  };

  //------------------------------------------------
  // Crud success/error
  //------------------------------------------------
  const afterCrudSuccess = (json) => {    
    alert(json.message);
    if (json.refresh_required) {
      listMetadata();
    }
  };

  //------------------------------------------------
  // message
  //------------------------------------------------
  const displayError = (json) => {
    $("#metadataArea .message-area").html(json.error);
    $("#metadataArea .message-area").show();
  };
  
  const hideMessageArea = () => {
    $("#metadataArea .message-area").empty();
    $("#metadataArea .message-area").hide();
  };

  //------------------------------------------------
  // Events on table
  //------------------------------------------------
  const onAfterChange = (changes, source) => {
    if (source !== "edit") {
      return;
    }

    const rowIndex = changes[0][0];
    const checked = changes[0][3];

    if (checked) {
      _selectedRecords[rowIndex] = _grid.getDataAtRow(rowIndex);
    } else {
      delete _selectedRecords[rowIndex];
    }
  };

  //------------------------------------------------
  // Create grid
  //------------------------------------------------
  const createGrid = (elementId, json = null) => {
    const hotElement = document.querySelector(elementId);

    if (_grid) {
      _grid.destroy();
    }

    const header = getColumns(json);
    const records = getRows(json);
    const columnsOption = getColumnsOption(json);
    const contextMenu = getContextMenuOption(json);

    const hotSettings = {
        data: records,
        height: 500,
        stretchH: "all",
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
        afterChange(changes, source) { return onAfterChange(changes, source); },
        licenseKey: "non-commercial-and-evaluation"
    };

    const hot = new Handsontable(hotElement, hotSettings);
    hot.updateSettings({afterColumnSort() {
      hot.render();
    }
    });

    _grid = hot;
  };

  const getColumns = (json) => {
    if (json && json.columns) {
      return json.columns;
    }

    return null;
  };

  const getRows = (json) => {
    if (json && json.rows) {
      return json.rows;
    }

    return null;
  };

  const getColumnsOption = (json) => {
    if (json && json.column_options) {
      return json.column_options;      
    }

    return [[]];
  };

  const getContextMenuOption = (json) => {
    if (json && json.context_menu) {
      return ["row_above", "row_below", "---------", "remove_row", "---------", "undo", "redo", "---------", "alignment"];
    }

    return false;
  };

  //------------------------------------------------
  // Misc
  //------------------------------------------------
  const lockForm = () => {
    $("#metadataArea #selected_directory").prop("disabled", true);
    $("#metadataArea #executListMetadataBtn").prop("disabled", true);    
  };

  const unlockForm = () => {
    $("#metadataArea #selected_directory").prop("disabled", false);
    $("#metadataArea #executListMetadataBtn").prop("disabled", false);    
  };

  const changeButtonStyles = (json) => {
    $("#updateMetadataBtn").prop("disabled", !json.api_updatable);
    $("#deleteMetadataBtn").prop("disabled", !json.api_deletable);
    $("#expandMetadataTree").prop("disabled", !json.api_readable);
    $("#collapseMetadataTree").prop("disabled", !json.api_readable);
    $("#retrieveMetadataBtn").prop("disabled", false);
  };

  const refreshTree = (json) => {
    $("#metadataArea #editMetadataTree").jstree(true).settings.core.data = json;
    $("#metadataArea #editMetadataTree").jstree(true).refresh();
    $("#metadataArea #editMetadataTree").jstree(true).settings.core.data = (node, callback) => readMetadata(node, callback);
  };

  const getSelectedRecords = () => Object.values(_selectedRecords);

  const getSelectedFullNames = () => JSON.stringify(Object.keys(_selectedFullNames));

  const disableButtons = () => {
    $("#updateMetadataBtn").prop("disabled", true);
    $("#deleteMetadataBtn").prop("disabled", true);
    $("#expandMetadataTree").prop("disabled", true);
    $("#collapseMetadataTree").prop("disabled", true);
    $("#retrieveMetadataBtn").prop("disabled", true);
  };
  
  const sleep = function(waitMsec) {
    const startMsec = new Date();
    while ((new Date - startMsec) < waitMsec) {}
  };

  const refreshSelectOptions = (result) => {    
    $("#metadataArea .metadata-select-list").html(result);
    $("#metadataArea .metadata-select-list").select2({
        dropdownAutoWidth : true,
        width: "auto",
        containerCssClass: ":all:",
        placeholder: PLACEHOLDER,
        allowClear: true
      });         
  };
  //------------------------------------------------
  // page load actions
  //------------------------------------------------
  disableButtons();

  $("#metadataArea .tab-area").tabs();

  $("#metadataArea #editMetadataTree").jstree({    
    "core" : {
      "check_callback"(operation, node, node_parent, node_position, more) { return validateEditTree(operation, node, node_parent, node_position, more); },
      "data" : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    },
    "plugins": ["dropdown"]
  });

  $("#metadataArea #deployMetadataResultTree").jstree({    
    "core" : {
      "data" : [],
      "multiple": false,
      "animation":false,
      "themes": {"icons":false}
    }
  });
};

$(document).ready(metadata);
$(document).on("page:load", metadata);
