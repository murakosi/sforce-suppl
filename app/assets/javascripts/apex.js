const apex = function() {
  
  let selectedTabId = 0;
  let currentTabIndex = 0;
  const grids = {};
  const logNames = {};
  const defaultDataType = "";
  const defaultContentType = null;
  const eventColumnIndex = 1;
  const USER_DEBUG = "USER_DEBUG";

  //------------------------------------------------
  // Shortcut keys
  //------------------------------------------------
  $(window).on('keydown', function(e) {
    if (e.target.id === "apex_code") {

      if (e.ctrlKey && (e.key === 'r' || e.keyCode === 13)) {  
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
  $('#apexArea #executeAnonymousBtm').on('click', function(e) {
    if ($.isAjaxBusy() || !$('#apexArea #apex_code').val()) {
      return false;
    }
  
    e.preventDefault();
    executeAnonymous();
  });
    
  const executeAnonymous = function() {
    hideMessageArea();
    selectedTabId = $("#apexArea .tabArea .ui-tabs-panel:visible").attr("tabId");

    const debugOptions = {};    
    $('#debugOptions option:selected').each(function() {
      const category = $(this).parent().attr("id");
      const level = $(this).val();
      debugOptions[category] = level;
    });
      
    const val = {code: $('#apexArea #apex_code').val(), debug_options: debugOptions};
    const action = $('#apexArea .execute-anonymous-form').attr('action');
    const method = $('#apexArea .execute-anonymous-form').attr('method');
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
    const callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null);
    $.executeAjax(options, callbacks);
  };
  
  const processSuccessResult = (json) => {
    const elementId = "#apexArea #apexGrid" + selectedTabId;
    logNames[elementId] = json.log_name;    
    $("#apexArea #logInfo" + selectedTabId).html(getLogResult(json));
    createGrid(elementId, json);
  };

  const getLogResult = (json) => {
    return json.log_name + '&nbsp;&nbsp;<label><input type="checkbox" class="debugOnly"/>&nbsp;Debug only</label>';
  }

  //------------------------------------------------
  // Debug options
  //------------------------------------------------  
  $('#apexArea #debugOptionBtn').on('click', function(e) {
    if ($('#debugOptions').is(":visible")) {
      $('#debugOptions').hide();
    } else {
      $('#debugOptions').show();
    }
  });

  //------------------------------------------------
  // CSV Download
  //------------------------------------------------
  $('#apexArea #downloadLogBtn').on('click', function(e) {
    const elementId = getActiveGridElementId();
    const logName = logNames[elementId];
    if (logName) {
      const hotElement = grids[elementId];
      hotElement.getPlugin('exportFile').downloadFile('csv', {
              bom: true,
              columnDelimiter: ',',
              columnHeaders: true,
              exportHiddenColumns: false,
              exportHiddenRows: false,
              fileExtension: 'csv',
              filename: logName,
              mimeType: 'text/csv',
              rowDelimiter: '\r\n',
              rowHeaders: true
      });
    }
  });

  //------------------------------------------------
  // Filter debug only
  //------------------------------------------------
  $("#apexArea").on("click", "input.debugOnly", function() {
    if ($(this).prop("checked")) {
      filterLog();
    } else {
      clearFilter();
    }
  });

  const filterLog = () => {
    const elementId = getActiveGridElementId();
    const hotElement = grids[elementId];    
    const filtersPlugin = hotElement.getPlugin('filters');
    filtersPlugin.removeConditions(eventColumnIndex);
    filtersPlugin.addCondition(eventColumnIndex, 'eq', [USER_DEBUG]);
    filtersPlugin.filter();
    hotElement.render();
  };


  const clearFilter = () => {
    const elementId = getActiveGridElementId();
    const hotElement = grids[elementId];
    const filtersPlugin = hotElement.getPlugin('filters');
    filtersPlugin.clearConditions();
    filtersPlugin.filter();
    hotElement.render();
  };

  //------------------------------------------------
  // Create tab
  //------------------------------------------------
  $(document).on('click', '#apexArea .ui-closable-tab', function(e) {

    if ($("#apexArea .tabArea ul li").length <= 2) {
      return false;
    }

    const panelId = $(this).closest("#apexArea li").remove().attr("aria-controls");
    $("#apexArea #" + panelId ).remove();
    $("#apexArea .tabArea").tabs("refresh");

    return false;
  });

  $('#apexArea .add-tab-btn').on('click', function(e) {
    createTab();
    return false;
  });
  
  const createTab = () => {
    currentTabIndex = currentTabIndex + 1;
    const newTabId = currentTabIndex;

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
    selectedTabId = newTabIndex;
    $("#apexArea .tabArea").tabs({ active: newTabIndex});
  };

  const setSortableAttribute = () => {
    if ($("#apexTabs li" ).length > 2) {
      $("#apexTabs").sortable("enable");
    } else {
      $("#apexTabs").sortable('disable');
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
    return grids[elementId];
  };

  //------------------------------------------------
  // Create grid
  //------------------------------------------------
  const createGrid = (elementId, json = null) => {

    const hotElement = document.querySelector(elementId);

    if (grids[elementId]) {
      const table = grids[elementId];
      table.destroy();
    }

    const header = getColumns(json);
    const records = getRows(json);
    const columnsOption = getColumnsOption(json);
    const height = json ? 500 : 0;

    const hotSettings = {
        data: records,
        //height: height,
        stretchH: 'last',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        fragmentSelection: 'cell',
        filters: true,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        trimWhitespace: false,
        licenseKey: 'non-commercial-and-evaluation'
    };

    const hot = new Handsontable(hotElement, hotSettings);
    grids[elementId] = hot;
    hot.render();
  };

  const getColumns = (json) => {
    if (json && json.columns) {
      return json.columns;
    } else {
      return null;
    }
  };
  
  const getRows = (json) => {
    if (json && json.rows) {
      return json.rows;
    } else {
      return null;
    }
  };

  const getExecuteResult = (json) => {
    if (json && json.result) {
      return json.result;
    } else {
      return null;
    }
  };

  const getColumnsOption = (json) => {
    if (json && json.columnOptions) {
      return json.columnOptions;
    } else {
      return null;
    }
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
  $("#apexTabs").sortable({items: 'li:not(.add-tab-li)', delay: 150});
  createTab();
};

$(document).ready(apex);
$(document).on('page:load', apex);
