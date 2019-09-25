const coordinates = function() {
  
  let currentTabIndex = 0;
  const grids = {};
  const sObjects = {};
  const THIS_AREA = "soqlArea";
  const defaultDataType = "";
  const defaultContentType = null;

  //------------------------------------------------
  // CreatGrid Dialog
  //------------------------------------------------
  $("#soqlArea #openCreatGridBtn").on('click', (e) => {
    $("#soqlOverRay").show();
  });

  $("#creatGridArea #cancelCreateBtn").on('click', (e) => {
    $("#soqlOverRay").hide();
  });

  $("#creatGridArea #createGridBtn").on('click', (e) => {
    createSObjectGrid();
  });

  const createSObjectGrid = () => {
    const rawFields = $("#creatGridArea #sobject_fields").val();
    const sobject = $('#creatGridArea #sobject_selection').val();
    const separator = $('#creatGridArea #sobjectFieldsSeparator').val();

    if (sobject && rawFields) {
      const action = "create";
      const val = {sobject, fields: rawFields, separator, tab_id: getActiveTabElementId()};
      $.get(action, val, function(json) {
        displayQueryResult(json);
        $("#soqlOverRay").hide();
      });
    }
  };
  
  $("#soqlArea .sobject-select-list").on("select2:open", (e) => {
    $(".select2-container--open").css("z-index","4010");
  });
    
  $("#soqlArea .sobject-select-list").on("select2:close", (e) => {
    $(".select2-container--open").css("z-index","1051");
  });
  
  //------------------------------------------------
  // SOQL History
  //------------------------------------------------
  $("#soqlArea #soqlHistoryBtn").on("click", (e) => {
    if ($("#soqlHistory").width() > 0) {
      closeSoqlHistory();
    } else {
      openSoqlHistory();
    }
  });
      
  $("#soqlHistory .closebtn").on("click", (e) => {
    closeSoqlHistory();
  });
    
  $('#soqlHistory').on('mouseover', 'li', function(e) {
    $(this).attr("title", $(this).text());
  });
    
  $('#soqlHistory').on('mouseout', 'li', function(e) {
    $(this).attr("title", "");
  });
  
  $('#soqlHistory').on('dblclick', 'li', function(e) {
    $("#soqlArea #input_soql").val($(this).text());
  });

  const openSoqlHistory = () => {
    $(".closebtn").show();
    $("#soqlHistory").width("250px");
    $("#soqlArea").css("margin-left","150px");
  };

  const closeSoqlHistory = () => {
    $(".closebtn").hide();
    $("#soqlHistory").width("0");
    $("#soqlArea").css("margin-left","0");    
  };
  
  //------------------------------------------------
  // Event on menu change
  //------------------------------------------------
  $(document).on('displayChange', (e, param) => {
    if (param.targetArea = THIS_AREA) {
      const elementId = getActiveGridElementId();
      const grid = grids[elementId];
      if (grid) {
        grid.render();
      }
    }
  });
    
  //------------------------------------------------
  // Shortcut keys
  //------------------------------------------------
  $(window).on('keydown', (e) => {
    
    if (e.ctrlKey && (e.key === 'r' || e.keyCode === 13)) {
      e.preventDefault();

      if (e.target.id === "input_soql") {        
        executeSoql();
        return false;
      }

      if ($("#soqlOverRay").is(":visible")) {
        createSObjectGrid();
        return false;
      }
    }

    if (e.keyCode === 27) {
      if ($("#soqlOverRay").is(":visible")) {
        $("#soqlOverRay").hide();
      }
    }
  
    if (e.keyCode === 9) {
      if (e.target.id === "input_soql") {
        insertTab(e);
        return false;
      }
    }
  });

  //------------------------------------------------
  // Insert Tab
  //------------------------------------------------
  const insertTab = (e) => {
    const elem = e.target;
    const start = elem.selectionStart;
    const end = elem.selectionEnd;
    elem.value = "" + (elem.value.substring(0, start)) + "\t" + (elem.value.substring(end));
    elem.selectionStart = elem.selectionEnd = start + 1;    
  };
  
  //------------------------------------------------
  // Execute SOQL
  //------------------------------------------------
  $('#soqlArea .execute-soql').on('click', (e) => {
    e.preventDefault();
    executeSoql();
  });
    
  const executeSoql = (params) => {
    let callbacks, queryAll, soql, tabId, tooling;
    if ($.isAjaxBusy()) {
      return false;
    }
      
    if (params) {
      soql = params.soql_info.soql
      tooling = params.soql_info.tooling
      queryAll = params.soql_info.query_all;
      tabId = params.soql_info.tab_id;
      if (params.soql_info.key_map) {
        updateGrid(tabId, params.soql_info);
      }
    } else {
      soql = $('#soqlArea #input_soql').val();
      tooling = $('#soqlArea #useTooling').is(':checked');
      queryAll = $('#soqlArea #queryAll').is(':checked');      
      tabId = getActiveTabElementId();
    }
    
    if (soql === null || soql === 'undefined' || soql === "") {
      endCrud();
      return false;
    }
      
    hideMessageArea();
    
    const val = {soql, tooling, query_all: queryAll, tab_id: tabId};
    const action = $('#soqlArea .soql-form').attr('action');
    const method = $('#soqlArea .soql-form').attr('method');
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);

    if (params && params.afterCrud) {
      callbacks = $.getAjaxCallbacks(processQuerySuccessAfterCrud, displayError, null);
    } else {
      callbacks = $.getAjaxCallbacks(processQuerySuccess, displayError, null);
    }

    $.executeAjax(options, callbacks);
  };
  
  const updateGrid = (tabId, soql_info) => {
    const elementId = "#soqlArea #grid" + tabId;
    const grid = grids[elementId];
    const sobject = sObjects[elementId];

    const columnOptions = [];
    const colcnt = sobject.columns.length;
    for (let col = 0; col < colcnt; col++){
      columnOptions.push({readOnly:true, type:"text"});
    }

    const cnt = grid.countRows();
    for (let row = 0; row < cnt; row++) {
      const id = grid.getCellMeta(row, sobject.idColumnIndex).tempId;
      const value = soql_info.key_map[id];
      grid.setDataAtCell(row, sobject.idColumnIndex, value, "loadData");
      grid.removeCellMeta(row, sobject.idColumnIndex, 'tempId');
    }

    delete sObjects[elementId];
    grid.updateSettings({columns:columnOptions});
    grid.render();
  };

  //------------------------------------------------
  // Query callbacks
  //------------------------------------------------  
  const processQuerySuccess = json => displayQueryResult(json);

  const processQuerySuccessAfterCrud = (json) => {
    displayQueryResult(json);
    endCrud();
  };

  const displayQueryResult = (json) => {
    const selectedTabId = json.soql_info.tab_id;
    $("#soqlArea #soql-info" + selectedTabId).html(json.soql_info.timestamp);
    const elementId = "#soqlArea #grid" + selectedTabId;

    sObjects[elementId] = {
                            rows: json.records.initial_rows, 
                            columns: json.records.columns,
                            editions:{},
                            sobject_type: json.sobject,
                            soql_info: json.soql_info,
                            idColumnIndex: json.records.id_column_index,
                            editable: json.records.id_column_index === null ? false : true,
                            tempIdPrefix: json.tempIdPrefix,
                            assignedIndex: 0
                          };

    createGrid(elementId, json.records);
    
    $("#soqlHistory ul").append('<li>' + json.soql_info.soql + '</li>');

    if (json.records.size <= 0) {
      const grid = grids[elementId];
      grid.getPlugin('AutoColumnSize').recalculateAllColumnsWidth();
      grid.render();
    }
  };

  //------------------------------------------------
  // CRUD
  //------------------------------------------------
  const executeCrud = (options) => {
    hideMessageArea();
    options["showProgress"] = false;
    const callbacks = $.getAjaxCallbacks(processCrudSuccess, processCrudError, null);
    beginCrud();
    $.executeAjax(options, callbacks);  
  };
    
  //------------------------------------------------
  // CRUD callbacks
  //------------------------------------------------
  const beginCrud = () => $("#overlay").show();
    
  const endCrud = () => $("#overlay").hide();
    
  const processCrudSuccess = (json) => {
    if (json.done) {
      executeSoql({soql_info:json.soql_info, afterCrud: true});
    } else {
      endCrud();
    }
  };
   
  const processCrudError = (json) => {
    displayError(json);
    endCrud();
  };

  //------------------------------------------------
  // Upsert
  //------------------------------------------------
  $('#soqlArea #upsertBtn').on('click', (e) => {
    e.preventDefault();
    executeUpsert();
  });
    
  const executeUpsert = () => {
    if ($.isAjaxBusy()) {
      return false;
    }
    
    const elementId = getActiveGridElementId();
    const sobject = sObjects[elementId];

    if (!sobject || !sobject.editable || $.isEmptyObject(sobject.editions)) {
      return false;
    }

    const val = {soql_info:sobject.soql_info, sobject: sobject.sobject_type, records: JSON.stringify(sobject.editions)};
    const action = "/update";
    const method = "post";
    const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
    executeCrud(options);
  };
    
  //------------------------------------------------
  // Delete
  //------------------------------------------------
  $('#soqlArea #deleteBtn').on('click', (e) => {
    e.preventDefault();
    executeDelete();
  });
    
  const executeDelete = () => {
    if ($.isAjaxBusy()) {
      return false;
    }
    
    const elementId = getActiveGridElementId();
    const sobject = sObjects[elementId];

    if (!sobject || !sobject.editable) {
      return false;
    }

    const hot = grids[elementId];
    const ids = getSelectedIds(hot, sobject);
    
    if (!ids || ids.length <= 0) {
      return false;
    }
  
    if (window.confirm("Are you sure?")) {
      const val = {soql_info:sobject.soql_info, ids};
      const action = "/delete";
      const method = "post";
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      executeCrud(options);
    }
  };
      
  //------------------------------------------------
  // Undelete
  //------------------------------------------------
  $('#soqlArea #undeleteBtn').on('click', (e) => { 
    e.preventDefault();
    executeUndelete();
  });
    
  const executeUndelete = () => {
    if ($.isAjaxBusy()) {
      return false;   
    }
    
    const elementId = getActiveGridElementId();
    const sobject = sObjects[elementId];

    if (!sobject || !sobject.editable) {
      return false;
    }

    const hot = grids[elementId];
    const ids = getSelectedIds(hot, sobject);
    
    if (!ids || ids.length <= 0) {
      return false;
    }
    
    if (window.confirm("Are you sure?")) {
      const val = {soql_info:sobject.soql_info, ids};
      const action = "/undelete";
      const method = "post";
      const options = $.getAjaxOptions(action, method, val, defaultDataType, defaultContentType);
      executeCrud(options);
    }
  };

  //------------------------------------------------
  // Edit on grid
  //------------------------------------------------ 
  const onAfterChange = (changes, source) => {

    if (source === 'loadData') {
      return;
    }

    for (let change of changes) {
      storeChanges(change);
    }
      
  };

  const storeChanges = (change) => {
    const rowIndex = change[0];
    const columnIndex = change[1];
    const oldValue = change[2];
    const newValue = change[3];

    if (oldValue === newValue) {
      return;
    }

    let isRestored = false;
    let isNewRow = false;

    const elementId = getActiveGridElementId();    
    const grid = grids[elementId];
    const sobject = sObjects[elementId];

    const fieldName = sobject.columns[columnIndex];  
    const id = getSalesforceId(grid, sobject, rowIndex);

    if (id.startsWith(sobject.tempIdPrefix)) {
      isNewRow = true;
    }

    if (sobject.editions[id]) {
      if (!isNewRow && (newValue === sobject.rows[id][columnIndex])) {
        delete sobject.editions[id][fieldName];
        if (Object.keys(sobject.editions[id]).length <= 0) {
          delete sobject.editions[id];
        }
        isRestored = true;
      } else {
        sobject.editions[id][fieldName] = newValue;
      }
    } else {
      sobject.editions[id] = {};
      sobject.editions[id][fieldName] = newValue;
    }
    
    if (isNewRow) {
      return;
    }
    
    if (isRestored) {
      grid.removeCellMeta(rowIndex, columnIndex, 'className');
    } else {
      grid.setCellMeta(rowIndex, columnIndex, 'className', 'changed-cell-border');
    }

    grid.render();
  };

  const getSalesforceId = (grid, sobject, rowIndex) => {
    const idColumnIndex = sobject.idColumnIndex
    const id = grid.getDataAtCell(rowIndex, idColumnIndex);

    if (id === "" || id === "undefined" || id === null) {
      return grid.getCellMeta(rowIndex, idColumnIndex).tempId;
    } else {
      return id;
    }
  };
      
  const getSelectedIds = (grid, sobject) => {
    let rowIndex;
    const selectedCells = grid.getSelected();

    if (!selectedCells) {
      return null;
    }

    const rows = {};

    let startRow = 0;
    let endRow = 0;

    for (let range of selectedCells) {
      if (range[0] <= range[2]) {
        startRow = range[0];
        endRow = range[2] + 1;
      } else {
        startRow = range[2];
        endRow = range[0] + 1;
      }

      for (let rowIndex = startRow; rowIndex < endRow; rowIndex++) {
        rows[rowIndex] = null;
      }
    }

    const ids = [];
    for (rowIndex of Object.keys(rows)) {
      const id = grid.getDataAtCell(rowIndex, sobject.idColumnIndex);
      if (id) {
        ids.push(id);
      }
    }
     
    return ids;
  };

  //------------------------------------------------
  // Add row
  //------------------------------------------------
  $('#soqlArea').on('click', ' .add-row', (e) => {
    addRow();
  });
    
  const addRow = () => {
    const elementId = getActiveGridElementId();
    if (!sObjects[elementId] || !sObjects[elementId].editable) {
      return;
    }

    const grid = grids[elementId];
    let selectedCell = getSelectedCell(grid);
    if (!selectedCell || selectedCell.row < 0) {
      selectedCell = {row: 0, col: 0};
    }

    grid.alter('insert_row', selectedCell.row + 1, 1);
    grid.selectCell(selectedCell.row, selectedCell.col);
  };
  
  const onAfterCreateRow = (index, amount, source) => {
    setTimeout(( () => assignTempId(index)), 3);
  };
    
  const assignTempId = (rowIndex) => {
    const elementId = getActiveGridElementId();
    const grid = grids[elementId];
    const sobject = sObjects[elementId];
    const newIndex = sobject.assignedIndex + 1;
    const tempId = sobject.tempIdPrefix + newIndex;
    sobject.assignedIndex = newIndex;
    grid.setCellMeta(rowIndex, sobject.idColumnIndex, 'tempId', tempId);
  };

  //------------------------------------------------
  // Remove row
  //------------------------------------------------
  $('#soqlArea').on('click', ' .remove-row', (e) => {
    removeRow();
  });
    
  const removeRow = () => {
    const elementId = getActiveGridElementId();
    if (!sObjects[elementId] || !sObjects[elementId].editable) {
      return;
    }

    const grid = grids[elementId];
    const selectedCell = getSelectedCell(grid);

    if (!selectedCell || selectedCell.row < 0) {
      return false;
    }

    grid.alter('remove_row', selectedCell.row, 1);
    grid.selectCell(getValidRowAfterRemove(selectedCell, grid), selectedCell.col);
  };
    
  const onBeforeRemoveRow = (index, amount, physicalRows, source) => {
    if (physicalRows.length !== 1) {
      return false;
    }

    const rowIndex = physicalRows[0];

    const elementId = getActiveGridElementId();
    const sobject = sObjects[elementId];
    const grid = grids[elementId];
    const tempId = grid.getCellMeta(rowIndex, sobject.idColumnIndex).tempId;

    if (!tempId) {
      return false;
    }

    if (sobject.editions[tempId]) {
      delete sobject.editions[tempId];    
    }
  };
    
  const getSelectedCell = (grid) => {
    const selectedCells = grid.getSelected();

    if (!selectedCells) {
      return null;    
    } else {
      return {
        row: selectedCells[0][0],
        col: selectedCells[0][1]
      };
    }
  };

  const getValidRowAfterRemove = (selectedCell, grid) => {
    const lastRow = grid.countVisibleRows() - 1;
    if (selectedCell.row > lastRow) {
      return lastRow;
    } else {
      return selectedCell.row;
    }
  };
      
  //------------------------------------------------
  // Active grid
  //------------------------------------------------
  const getActiveTabElementId = () => {
    return $("#soqlArea .tabArea .ui-tabs-panel:visible").attr("tabId");
  };

  const getActiveGridElementId = () => {
    return "#soqlArea #grid" + getActiveTabElementId();
  };
    
  const getActiveGrid = () => {
    const elementId = getActiveGridElementId();
    return grids[elementId];
  };

  //------------------------------------------------
  // CSV Download
  //------------------------------------------------
  $('#soqlArea .export-btn').on('click', (e) => {
    const elementId = getActiveGridElementId();
    const sobject = sObjects[elementId];
    if (sobject) {
      const hotElement = getActiveGrid();
      hotElement.getPlugin('exportFile').downloadFile('csv', {
          bom: true,
          columnDelimiter: ',',
          columnHeaders: true,
          exportHiddenColumns: false,
          exportHiddenRows: false,
          fileExtension: 'csv',
          filename: 'soql_result(' + sobject.sobject_type + ')',
          mimeType: 'text/csv',
          rowDelimiter: '\r\n',
          rowHeaders: false
      });
    }
  });

  //------------------------------------------------
  // Rerun SOQL
  //------------------------------------------------
  $('#soqlArea').on('click', '.rerun', (e) => {
    if ($.isAjaxBusy()) {
      return false;
    }

    e.preventDefault();
    
    const elementId = getActiveGridElementId();
    
    if (sObjects[elementId]) {
      executeSoql({soql_info:sObjects[elementId].soql_info, afterCrud: false});
    }
  });
      
  //------------------------------------------------
  // Show Query
  //------------------------------------------------
  $('#soqlArea').on('click', '.show-query', (e) => {
    if ($.isAjaxBusy()) {
      return false;
    }

    e.preventDefault();
    
    const elementId = getActiveGridElementId();
    
    if (sObjects[elementId] && sObjects[elementId].soql_info.soql) {
      const width = 750;
      const height = 400;
      const left =(screen.width - width) / 2;
      const top = (screen.height - height) / 2;
      let options = "location=0, resizable=1, menubar=0, scrollbars=1";
      options += ", left=" + left + ", top=" + top + ", width=" + width + ", height=" + height;
      const popup = window.open("", "soql", options);
      popup.document.write("<pre>" + sObjects[elementId].soql_info.soql  + "</pre>");
    }
  });
      
  //------------------------------------------------
  // Close tab
  //------------------------------------------------
  $(document).on('click', '#soqlArea .ui-closable-tab', function(e) {
    if ($.isAjaxBusy()) {
      return;
    }
    
    e.preventDefault();

    if ($("#soqlArea .tabArea ul li").length <= 2) {
      return;
    }

    const panelId = $(this).closest("#soqlArea li").remove().attr("aria-controls");
    $("#soqlArea #" + panelId ).remove();
    $("#soqlArea .tabArea").tabs("refresh");
    setSortableAttribute();
  });

  //------------------------------------------------
  // Create tab
  //------------------------------------------------
  $("#soqlArea .add-tab-btn").on('click', (e) => {
    createTab();
  });
  
  const createTab = () => {
    currentTabIndex = currentTabIndex + 1;
    const newTabId = currentTabIndex;

    $("#soqlArea .tabArea ul li:last").before(
      '<li class="noselect"><a href="#tab' + newTabId + '">Grid' + newTabId + '</a>' +
      '<span class="ui-icon ui-icon-close ui-closable-tab"></span>' +
      '</li>'
    );

    let inputArea = '<div class="inputSoql" style="margin-bottom:-2px;" tabId="' + newTabId + '">';
    inputArea += '<textarea name="input_soql" id="input_soql' + newTabId + '" style="width:100%" rows="5"></textarea>';
    inputArea += '</div>';

    let soqlArea = '<div class="resultSoql" tabId="' + newTabId + '">';    
    soqlArea += '<div id="soql' + newTabId + '">';
    soqlArea += '<button name="showQueryBtn" type="button" class="show-query btn btn-xs btn-default in-btn">Query</button>';
    soqlArea += '<button name="insRowBtn" type="button" class="add-row btn btn-xs btn-default in-btn">Insert row</button>';
    soqlArea += '<button name="remRowBtn" type="button" class="remove-row btn btn-xs btn-default in-btn">Remove row</button>';
    soqlArea += '<button name="rerunBtn" type="button" class="rerun btn btn-xs btn-default in-btn">Rerun</button>';
    soqlArea += '</div>';
    soqlArea += '<div id="soql-info' + newTabId + '">0 rows</div>';
    soqlArea += '</div>';
    
    $("#soqlArea .tabArea").append(
      '<div id="tab' + newTabId + '" class="resultTab" tabId="' + newTabId + '">' +
      //inputArea + 
      soqlArea +
      '<div id="grid' + newTabId + '" class="resultGrid" tabId="' + newTabId + '"></div>' +
      '</div>'
    );
    
    $("#soqlArea .tabArea").tabs("refresh");
        
    setSortableAttribute();
    
    const newTabIndex = $("#soqlArea .tabArea ul li").length - 2;
    const selectedTabId = newTabIndex;
    $("#soqlArea .tabArea").tabs({ active: newTabIndex, activate: onTabSelect});
  };

  const onTabSelect = (event, ui) => {
    const tabId = ui.newPanel.attr("tabId");
    const elementId = "#soqlArea #grid" + tabId;
    if (grids[elementId]){
      grids[elementId].render();
    }
  };

  const setSortableAttribute = () => {
    if ($("#soqlTabs li" ).length > 2) {
      $("#soqlTabs").sortable("enable");
    } else {
      $("#soqlTabs").sortable('disable');
    }
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
        height,
        //stretchH: stretch,
        autoWrapCol: false,
        autoWrapRow: false,
        allowRemoveColumn: false,
        manualRowResize: false,
        manualColumnResize: true,
        rowHeaders: true,
        colHeaders: header,
        columns: columnsOption,
        startRows: 0,
        minSpareRows: 0,
        minSpareCols: 0,
        fillHandle: {autoInsertRow: false},
        //fragmentSelection: true,
        columnSorting: true,
        //contextMenu: true,
        //colWidths: (i) -> setColWidth(i),
        outsideClickDeselects: false,
        licenseKey: 'non-commercial-and-evaluation',
        afterChange(source, changes) { return onAfterChange(source, changes); },
        afterOnCellMouseDown(event, coords, td) { return onCellClick(event, coords, td); },
        afterCreateRow(index, amount, source) { return onAfterCreateRow(index, amount, source); },
        beforeRemoveRow(index, amount, physicalRows, source) { return onBeforeRemoveRow(index, amount, physicalRows, source); },
        beforeCopy(data, coords) { return onBeforeCopy(data, coords); }
    };

    const hot = new Handsontable(hotElement, hotSettings);
    hot.updateSettings({afterColumnSort() {
      hot.render();
    }
    });

    grids[elementId] = hot;
  };

  const onBeforeCopy = (data, coords) => {
    const elementId = getActiveGridElementId();
    const sobject = sObjects[elementId];
    let count = 0;
    const target = coords[0];
    count = (target.endCol - target.startCol) + 1;
    
    if (count === sobject.columns.length) {
      data.unshift(sobject.columns);
    }
  };
    
  const setColWidth = (i) => {
    if (i === 0) {
      return 30;
    } else {
      return 200;
    }
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
    if (json && json.column_options){
      return json.column_options;
    }

    return [[]];
  };

  const onCellClick = (event, coords, td) => {
    //selectedCell = coords
  };
      
  //------------------------------------------------
  // message
  //------------------------------------------------
  const displayError = (json) => {
    $("#soqlArea .messageArea").html(json.error);
    $("#soqlArea .messageArea").show();
  };
  
  const hideMessageArea = () => {
    $("#soqlArea .messageArea").empty();
    $("#soqlArea .messageArea").hide();
  };

  //------------------------------------------------
  // page load actions
  //------------------------------------------------
  $("#soqlArea .tabArea").tabs(); 
  $("#soqlTabs").sortable({items: 'li:not(.add-tab-li)', delay: 150});
  createTab();
  
  for(let i = 0; i<200;i++){
    $("#soqlHistory ul").append('<li>aaaaaaaaaaaaaaaaaaa</li>');
  }

};

$(document).ready(coordinates);
$(document).on('page:load', coordinates);
