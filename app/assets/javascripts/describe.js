const describe = () => {

  let _currentTabIndex = 0;
  let _selectedTabId = null;
  let _suppressSObjectTypeChange = false;
  const _sObjects = {};
  const _grids = {};
  const DEFAULT_DATA_TYPE = "";  
  const DEFAULT_CONTENT_TYPE = null;
  const PLACEHOLDER = "Select an sObject";
    
  //------------------------------------------------
  // Shortcut keys
  //------------------------------------------------
  $(window).on("keydown", (e) => {

    if ($("#describeArea").is(":visible")) {

      if (e.ctrlKey && (e.key === "r" || e.keyCode === 13)) {
        executeDescribe();
        return false;
      }

      // escape
      if (e.keyCode === 27) {
        if ($.isAjaxBusy()) {
          $.abortAjax();
        }
        enableOptions();
      }      
    }
  });

  $(document).on("afterRefreshSObjects", (e, param) => {
    refreshSelectOptions(param.result);
    $("#sobjectTypeCheckBox_all").prop("checked", true);
  });

  //------------------------------------------------
  // Change custom/standard
  //------------------------------------------------
  $(".sobjectTypeCheckBox").on("click", (e) => {
    if ($.isAjaxBusy()) {
      return false;
    }
  });
  
  $(".sobjectTypeCheckBox").on("change", (e) => {
    disableOptions();
    const val = {object_type: e.target.value};
    const action = $("#filterSObjectList").attr("action");
    const method = $("#filterSObjectList").attr("method");
    const options = $.getAjaxOptions(action, method, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(refreshSelectOptions, displayError, null);
    $.executeAjax(options, callbacks, true);
  });

  const disableOptions = () => {
    $("#describeArea .sobject-select-list").prop("disabled", true);
    $("#sobjectTypeCheckBox_all").prop("disabled", true);
    $("#sobjectTypeCheckBox_standard").prop("disabled", true);
    $("#sobjectTypeCheckBox_custom").prop("disabled", true);
    $("#executeDescribeBtn").prop("disabled", true);
  };

  const enableOptions = () => {
    $("#describeArea .sobject-select-list").prop("disabled", false);
    $("#sobjectTypeCheckBox_all").prop("disabled", false);
    $("#sobjectTypeCheckBox_standard").prop("disabled", false);
    $("#sobjectTypeCheckBox_custom").prop("disabled", false);
    $("#executeDescribeBtn").prop("disabled", false);
  };

  //------------------------------------------------
  // describe
  //------------------------------------------------
  $("#executeDescribeBtn").on("click", (e) => {
    executeDescribe();
  });

  const executeDescribe = () => {
    if ($.isAjaxBusy()) {
      return;
    }

    hideMessageArea();
    _selectedTabId = getActiveTabElementId();
    const sobject = $("#describeArea #sobject_selection").val();
    if (sobject) {
      disableOptions();
      const val = {selected_sobject: sobject};
      const action = $("#executeDescribeBtn").attr("action");
      const method = $("#executeDescribeBtn").attr("method");
      const options = $.getAjaxOptions(action, method, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
      const callbacks = $.getAjaxCallbacks(afterExecuteDescribe, displayError, null);
      $.executeAjax(options, callbacks);
    }
  };

  //------------------------------------------------
  // CSV Download
  //------------------------------------------------
  $("#describeArea .export-btn").on("click", (e) => {
    const elementId = getActiveGridElementId();
    const sobjectName = _sObjects[elementId];
    if (sobjectName) {
      const hotElement = getActiveGrid();
      hotElement.getPlugin("exportFile").downloadFile("csv", {
          bom: false,
          columnDelimiter: ",",
          columnHeaders: true,
          exportHiddenColumns: false,
          exportHiddenRows: false,
          fileExtension: "csv",
          filename: sobjectName,
          mimeType: "text/csv",
          rowDelimiter: "\r\n",
          rowHeaders: false
      });
    }
  });

  //------------------------------------------------
  // callbacks
  //------------------------------------------------  
  const displayError = (json) => {
    $("#describeArea .messageArea").html(json.error);
    $("#describeArea .messageArea").show();
    enableOptions();
  };
  
  const hideMessageArea = () => {
    $("#describeArea .messageArea").empty();
    $("#describeArea .messageArea").hide();
  };

  const afterExecuteDescribe = (json) => {
    $("#describeArea #overview" + _selectedTabId).html(getDescribeInfo(json));
    const elementId = "#describeArea #describeGrid" + _selectedTabId;
    _sObjects[elementId] = json.sobject_name;
    createGrid(elementId, json);
    enableOptions();
  };

  const getDescribeInfo = (json) => {
    return '<label class="noselect">Label：</label>' + json.sobject_label + '<br>' +
           '<label class="noselect">API Name：</label>' + json.sobject_name + '<br>' +
           '<label class="noselect">Prefix：</label>' + json.sobject_prefix;
  };

  const refreshSelectOptions = (result) => {
    $("#describeArea .sobject-select-list").html(result);
    $("#describeArea .sobject-select-list").select2({
        dropdownAutoWidth : true,
        width: "auto",
        containerCssClass: ":all:",
        placeholder: PLACEHOLDER,
        allowClear: true
      });
    enableOptions();
  };

  //------------------------------------------------
  // Active grid
  //------------------------------------------------
  const getActiveTabElementId = () => {
    return $("#describeArea .tabArea .ui-tabs-panel:visible").attr("tabId");
  }

  const getActiveGridElementId = () => {
    return "#describeArea #describeGrid" + getActiveTabElementId();
  };
    
  const getActiveGrid = () => {
    const elementId = getActiveGridElementId();
    return _grids[elementId];
  };

  //------------------------------------------------
  // Close tab
  //------------------------------------------------
  $(document).on("click", "#describeArea .ui-closable-tab", function(e) {
    if ($.isAjaxBusy()) {
      return;
    }

    if ($("#describeArea .tabArea ul li").length <= 2) {
      return;
    }

    const panelId = $(this).closest("#describeArea li").remove().attr("aria-controls");
    $("#describeArea #" + panelId ).remove();
    $("#describeArea .tabArea").tabs("refresh");
  });

  //------------------------------------------------
  // Create tab
  //------------------------------------------------
  $("#describeArea .add-tab-btn").on("click", (e) => {
    createTab();
  });
  
  const createTab = () => {
    _currentTabIndex = _currentTabIndex + 1;
    const newTabId = _currentTabIndex;

    $("#describeArea .tabArea ul li:last").before(
      '<li class="noselect"><a href="#describeTab' + newTabId + '">Grid' + newTabId + '</a>' +
      '<span class="ui-icon ui-icon-close ui-closable-tab"></span>' +
      '</li>'
    );

    const overviewArea = '<div id="overview' + newTabId + '" class="resultSoql" tabId="' + newTabId + '"></div>';    
    
    $("#describeArea .tabArea").append(
      '<div id="describeTab' + newTabId + '" class="resultTab" tabId="' + newTabId + '">' +
      overviewArea +
      '<div id="describeGrid' + newTabId + '" class="resultGrid" tabId="' + newTabId + '"></div>' +
      '</div>'
    );
    
    createGrid("#describeArea #describeGrid" + newTabId);
    
    $("#describeArea .tabArea").tabs("refresh");

    setSortableAttribute();
    
    const newTabIndex = $("#describeArea .tabArea ul li").length - 2;
    _selectedTabId = newTabIndex;
    $("#describeArea .tabArea").tabs({ active: newTabIndex});
  };

  const setSortableAttribute = () => {
    if ($("#describeTabs li" ).length > 2) {
      $("#describeTabs").sortable("enable");
    } else {
      $("#describeTabs").sortable('disable');
    }
  };

  //------------------------------------------------
  // grid
  //------------------------------------------------ 
  const createGrid = (elementId, json = null) => {   
    const hotElement = document.querySelector(elementId);
    
    if (_grids[elementId]) {
      const table = _grids[elementId];
      table.destroy();
    }

    const header = getColumns(json);
    const records = getRows(json);
    const columnsOption = getColumnsOption(json);
    const height = json ? 500 : 0;

    const hotSettings = {
        data: records,
        colWidths: "200px",
        height: height,
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        fragmentSelection: "cell",
        columnSorting: true,
        filters: true,
        dropdownMenu: ["filter_action_bar", "filter_by_value"],
        licenseKey: "non-commercial-and-evaluation"
    };

    const hot = new Handsontable(hotElement, hotSettings);
    hot.updateSettings({afterColumnSort() {
      hot.render();
    }
    });

    _grids[elementId] = hot;
  };

  const getColumns = (json) => {
    if (json && json.columns){
      return json.columns;
    }
    
    return null;
  };

  const getRows = (json) => {
    if (json && json.rows){
      return json.rows;
    }

    return null;
  };

  const getColumnsOption = (json) => {
    if (json && json.column_options) {
      return json.column_options
    }

    return null;
  };

  const getColWidths = (json) => {
    if (!json || !json.columns){
      return null;
    }
      
    let widths = [];
    for(let column of json.columns){
      widths.push(getTextWidth(column, "20pt Verdana,Arial,sans-serif"));
    }

    return widths;
  };

  const getTextWidth = (text, font) => {
    const canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    const context = canvas.getContext("2d");
    context.font = font;
    const metrics = context.measureText(text);
    return metrics.width;
  };  

  //------------------------------------------------
  // page load actions
  //------------------------------------------------
  $("#describeArea .tabArea").tabs();
  $("#describeTabs").sortable({items: "li:not(.add-tab-li)", delay: 150});
  createTab();
  
};

$(document).ready(describe);
$(document).on("page:load", describe);
