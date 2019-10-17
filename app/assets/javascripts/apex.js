const apex = function() {
  
  let _selectedTabId = 0;
  let _currentTabIndex = 0;
  const _grids = {};
  const _logNames = {};
  const DEFAULT_DATA_TYPE = "";
  const DEFAULT_CONTENT_TYPE = null;
  const EVENT_COLUMN_INDEX = 1;
  const USER_DEBUG = "USER_DEBUG";

  //------------------------------------------------
  // Shortcut keys
  //------------------------------------------------
  $(window).on("keydown", (e) => {
    if (e.target.id === "apexCode") {

      if (e.ctrlKey && (e.key === "r" || e.keyCode === 13)) {  
        executeAnonymous();
        return false;
      }

      if (e.keyCode === 9) {
        const elem = e.target;
        const start = elem.selectionStart;
        const end = elem.selectionEnd;
        elem.value = "" + (elem.value.substring(0, start)) + "\t" + (elem.value.substring(end));
        elem.selectionStart = elem.selectionEnd = start + 1;
        return false;
      }
    }
  });

  //------------------------------------------------
  // Execute Anonymous
  //------------------------------------------------
  $("#apexArea #executeAnonymousBtn").on("click", (e) => {
    if ($.isAjaxBusy() || !$("#apexArea #apexCode").val()) {
      return false;
    }
  
    e.preventDefault();
    executeAnonymous();
  });
    
  const executeAnonymous = () => {
    hideMessageArea();
    _selectedTabId = $("#apexArea .tabArea .ui-tabs-panel:visible").attr("tabId");

    const debugOptions = {};    
    $("#debugOptions option:selected").each(function() {
      const category = $(this).parent().attr("id");
      const level = $(this).val();
      debugOptions[category] = level;
    });
      
    const val = {code: $("#apexArea #apexCode").val(), debug_options: debugOptions};
    const action = $("#apexArea .execute-anonymous-form").attr("action");
    const method = $("#apexArea .execute-anonymous-form").attr("method");
    const options = $.getAjaxOptions(action, method, val, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
    const callbacks = $.getAjaxCallbacks(afterExecuteAnonymous, displayError, null);
    $.executeAjax(options, callbacks);
  };
  
  const afterExecuteAnonymous = (json) => {
    const elementId = "#apexArea #apexGrid" + _selectedTabId;
    _logNames[elementId] = json.log_name;    
    $("#apexArea #logInfo" + _selectedTabId).html(getLogResult(json));
    createGrid(elementId, json);
  };

  const getLogResult = (json) => {
    return json.log_name + '&nbsp;&nbsp;<label><input type="checkbox" class="debug-only"/>&nbsp;Debug only</label>';
  }

  //------------------------------------------------
  // Debug options
  //------------------------------------------------  
  $("#apexArea #debugOptionBtn").on("click", (e) => {
    if ($("#debugOptions").is(":visible")) {
      $("#debugOptions").hide();
    } else {
      $("#debugOptions").show();
    }
  });

  //------------------------------------------------
  // CSV Download
  //------------------------------------------------
  $("#apexArea #downloadLogBtn").on("click", (e) => {
    const elementId = getActiveGridElementId();
    const logName = _logNames[elementId];
    if (logName) {
      const hotElement = _grids[elementId];
      hotElement.getPlugin("exportFile").downloadFile("csv", {
              bom: true,
              columnDelimiter: ",",
              columnHeaders: true,
              exportHiddenColumns: false,
              exportHiddenRows: false,
              fileExtension: "csv",
              filename: logName,
              mimeType: "text/csv",
              rowDelimiter: "\r\n",
              rowHeaders: true
      });
    }
  });

  //------------------------------------------------
  // Filter debug only
  //------------------------------------------------
  $("#apexArea").on("click", "input.debug-only", function(e) {
    if ($(this).prop("checked")) {
      filterLog();
    } else {
      clearFilter();
    }
  });

  const filterLog = () => {
    const elementId = getActiveGridElementId();
    const hotElement = _grids[elementId];    
    const filtersPlugin = hotElement.getPlugin("filters");
    filtersPlugin.removeConditions(EVENT_COLUMN_INDEX);
    filtersPlugin.addCondition(EVENT_COLUMN_INDEX, "eq", [USER_DEBUG]);
    filtersPlugin.filter();
    hotElement.render();
  };


  const clearFilter = () => {
    const elementId = getActiveGridElementId();
    const hotElement = _grids[elementId];
    const filtersPlugin = hotElement.getPlugin("filters");
    filtersPlugin.clearConditions();
    filtersPlugin.filter();
    hotElement.render();
  };

  //------------------------------------------------
  // Close tab
  //------------------------------------------------
  $(document).on("click", "#apexArea .ui-closable-tab", function(e) {

    if ($("#apexArea .tabArea ul li").length <= 2) {
      return;
    }

    const panelId = $(this).closest("#apexArea li").remove().attr("aria-controls");
    $("#apexArea #" + panelId ).remove();
    $("#apexArea .tabArea").tabs("refresh");
  });

  //------------------------------------------------
  // Create tab
  //------------------------------------------------
  $("#apexArea .add-tab-btn").on("click", (e) => {
    createTab();
  });
  
  const createTab = () => {
    _currentTabIndex = _currentTabIndex + 1;
    const newTabId = _currentTabIndex;

    $("#apexArea .tabArea ul li:last").before(
      '<li class="noselect"><a href="#apexTab' + newTabId + '">Grid' + newTabId + '</a>' +
      '<span class="ui-icon ui-icon-close ui-closable-tab"></span>' +
      '</li>'
    );

    const logInfoArea = '<div id="logInfo' + newTabId + '" class="resultSoql" tabId="' + newTabId + '"></div>';
    
    $("#apexArea .tabArea").append(
      '<div id="apexTab' + newTabId + '" class="resultTab" tabId="' + newTabId + '">' +
      logInfoArea +
      '<div id="apexGrid' + newTabId + '" class="resultGrid" tabId="' + newTabId + '"></div>' +
      '</div>'
    );
    
    createGrid("#apexArea #apexGrid" + newTabId);
    
    $("#apexArea .tabArea").tabs("refresh");

    setSortableAttribute();
    
    const newTabIndex = $("#apexArea .tabArea ul li").length - 2;
    _selectedTabId = newTabIndex;
    $("#apexArea .tabArea").tabs({ active: newTabIndex});
  };

  const setSortableAttribute = () => {
    if ($("#apexTabs li" ).length > 2) {
      $("#apexTabs").sortable("enable");
    } else {
      $("#apexTabs").sortable("disable");
    }
  };

  //------------------------------------------------
  // Active grid
  //------------------------------------------------
  const getActiveTabElementId = () => {
    return $("#apexArea .tabArea .ui-tabs-panel:visible").attr("tabId");
  };

  const getActiveGridElementId = () => {
    return "#apexArea #apexGrid" + getActiveTabElementId();
  };
    
  const getActiveGrid = () => {
    const elementId = getActiveGridElementId();
    return _grids[elementId];
  };

  //------------------------------------------------
  // Create grid
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
        height: height,
        stretchH: "last",
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        fragmentSelection: "cell",
        filters: true,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        trimWhitespace: false,
        licenseKey: "non-commercial-and-evaluation"
    };

    const hot = new Handsontable(hotElement, hotSettings);
    _grids[elementId] = hot;
    hot.render();
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

  const getExecuteResult = (json) => {
    if (json && json.result) {
      return json.result;
    }

    return null;    
  };

  const getColumnsOption = (json) => {
    if (json && json.columnOptions) {
      return json.columnOptions;
    }
    
    return null;
  };
      
  //------------------------------------------------
  // message
  //------------------------------------------------
  const displayError = (json) => {
    $("#apexArea .messageArea").html(json.error);
    $("#apexArea .messageArea").show();
  };
  
  const hideMessageArea = () => {
    $("#apexArea .messageArea").empty();
    $("#apexArea .messageArea").hide();
  };
    
  //------------------------------------------------
  // page load actions
  //------------------------------------------------
  $("#apexArea .tabArea").tabs();
  $("#apexTabs").sortable({items: "li:not(.add-tab-li)", delay: 150});
  createTab();
};

$(document).ready(apex);
$(document).on("page:load", apex);
