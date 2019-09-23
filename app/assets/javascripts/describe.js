const describe = () => {

  let currentTabIndex = 0;
  let selectedTabId = null;  
  const defaultDataType = "";  
  const defaultContentType = null;
  const sObjects = {};
  const grids = {};
    
  //------------------------------------------------
  // Shortcut keys
  //------------------------------------------------
  $(window).on('keydown', function(e) {

    if ($("#describeArea").is(":visible")) {

      if (e.ctrlKey && (e.key === 'r' || e.keyCode === 13)) {
        executeDescribe();
        return false;
      }
    }
  });

  //------------------------------------------------
  // change custom/standard
  //------------------------------------------------
  $('.sobjectTypeCheckBox').on('click', function(e) {
    if ($.isAjaxBusy()) {
      return false;
    }
  });
  
  $('.sobjectTypeCheckBox').on('change', function(e) {
    e.stopPropagation();
    e.preventDefault();

    disableOptions();
    const val = {object_type: e.target.value};
    const action = $('#filterSObjectList').attr('action');
    const method = $('#filterSObjectList').attr('method');
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType, false);
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
  $('#executeDescribeBtn').on('click', function(e) {
    e.preventDefault();
    executeDescribe();
  });

  const executeDescribe = () => {
    if ($.isAjaxBusy()) {
      return false;
    }

    selectedTabId = getActiveTabElementId();
    const sobject = $('#describeArea #sobject_selection').val();
    if (sobject) {
      disableOptions();
      const val = {selected_sobject: sobject};
      const action = $('#executeDescribeBtn').attr('action');
      const method = $('#executeDescribeBtn').attr('method');
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      const callbacks = $.getAjaxCallbacks(processSuccessResult, displayError, null);
      $.executeAjax(options, callbacks);
    }
  };

  //------------------------------------------------
  // CSV Download
  //------------------------------------------------
  $('#describeArea .export-btn').on('click', function(e) {
    const elementId = getActiveGridElementId();
    const sobjectName = sObjects[elementId];
    if (sobjectName) {
      const hotElement = getActiveGrid();
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
    enableOptions();
  };

  const processSuccessResult = (json) => {
    hideMessageArea();
    $("#describeArea #overview" + selectedTabId).html(getExecutedMethod(json));
    const elementId = "#describeArea #describeGrid" + selectedTabId;
    sObjects[elementId] = json.sobject_name;
    createGrid(elementId, json);
  };

  const refreshSelectOptions = (result) => {
    $('#describeArea .sobject-select-list').html(result);
    $('#describeArea .sobject-select-list').select2({
        dropdownAutoWidth : true,
        width: 'element',
        containerCssClass: ':all:',
        placeholder: "Select an sObject",
        allowClear: true
      });
    enableOptions();
  };

  //------------------------------------------------
  // Active grid
  //------------------------------------------------
  const getActiveTabElementId = () => $("#describeArea .tabArea .ui-tabs-panel:visible").attr("tabId");

  const getActiveGridElementId = () => {
    return "#describeArea #describeGrid" + getActiveTabElementId();
  };
    
  const getActiveGrid = () => {
    const elementId = getActiveGridElementId();
    return grids[elementId];
  };

  //------------------------------------------------
  // Create tab
  //------------------------------------------------
  $(document).on('click', '#describeArea .ui-closable-tab', function(e) {
    e.preventDefault();

    if ($("#describeArea .tabArea ul li").length <= 2) {
      return false;
    }

    const panelId = $(this).closest("#describeArea li").remove().attr("aria-controls");
    $("#describeArea #" + panelId ).remove();
    $("#describeArea .tabArea").tabs("refresh");
  });

  $('#describeArea .add-tab-btn').on('click', function(e) {
    e.preventDefault();
    createTab();
  });
  
  const createTab = () => {
    currentTabIndex = currentTabIndex + 1;
    const newTabId = currentTabIndex;

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
    selectedTabId = newTabIndex;
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
        //stretchH: 'all',
        autoWrapRow: true,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        //columns: columnsOption,
        contextMenu: false,
        readOnly: true,
        startRows: 0,
        fragmentSelection: 'cell',
        columnSorting: true,
        filters: true,
        dropdownMenu: ['filter_action_bar', 'filter_by_value'],
        licenseKey: 'non-commercial-and-evaluation'
    };

    const hot = new Handsontable(hotElement, hotSettings);
    hot.updateSettings({afterColumnSort() {
      hot.render();
    }
    });

    grids[elementId] = hot;
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

  const getExecutedMethod = (json) => {
    if (json && json.method){
      return json.method;
    }

    return null;
  };

  const getColumnsOption = (json) => {
    if (json && json.column_options) {
      return json.column_options
    }

    return null;
  };

  if ($("#describeArea").length) {
    $("#describeArea .tabArea").tabs();
    $("#describeTabs").sortable({items: 'li:not(.add-tab-li)', delay: 150});
    createTab();
  }
};

$(document).ready(describe);
$(document).on('page:load', describe);
