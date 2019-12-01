const soql = function() {
  let _selectedAnchor = null;
  let _anchorObject = null;  
  const DEFAULT_DATA_TYPE = "";
  const DEFAULT_CONTENT_TYPE = null;
  const SOBJECTS_PLACEHOLDER = "Select an sObject";
  const METADATA_PLACEHOLDER = "Select a metadata type";
  const GET = "get";

  //------------------------------------------------
  // Menu list
  //------------------------------------------------
  $("#menus").on("click", "a", function(e) {

    const clickedAnchor = $(this).prop("id");

    if (_selectedAnchor === clickedAnchor) {
      return;
    }

    _selectedAnchor = clickedAnchor;
    _anchorObject = this;

    changeDisplayDiv(_selectedAnchor);      
    return;    

  });
  
  const changeDisplayDiv = (target) => {
    
    changeAnchorClass(_anchorObject);

    $("div#mainArea").prop("class", target);
    
    $(document).trigger("afterDisplayChange", [{targetArea: target + "Area"}]);
  };

  const changeAnchorClass = (target) => {
    $(".menu-item").not(target).removeClass("displayed");

    if ($(target).hasClass("displayed")) {
      $(target).removeClass("displayed");
    } else {
      $(target).addClass("displayed");
    }
  };

  //------------------------------------------------
  // sObjects
  //------------------------------------------------
  const prepareSObjectLists = () => {
    $(".sobject-select-list").select2({
        dropdownAutoWidth : true,
        width: "auto",
        containerCssClass: ":all:",
        placeholder: SOBJECTS_PLACEHOLDER,
        allowClear: true
        });
  };

  $("#refreshSObjects").on("click", function(e) {
    beginRefresh();
    const action = $(this).attr("action");
    const options = $.getAjaxOptions(action, GET, {}, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(afterRefreshSObjects, onRefreshError, null);
    $.executeAjax(options, callbacks);
  });

  const afterRefreshSObjects = (json) => {
    $(document).trigger("afterRefreshSObjects", [{result: json.result}]);
    endRefresh();
  }

  //------------------------------------------------
  // Metadata
  //------------------------------------------------
  const prepareMetadataTypes = () => {
    const targetSelect2 = "div#metadataArea .metadata-select-list";
    $(targetSelect2).select2({
      dropdownAutoWidth : true,
      width: "auto",
      containerCssClass: ":all:",
      placeholder: METADATA_PLACEHOLDER,
      allowClear: true
      });    
  }

  $("#refreshMetadata").on("click", function(e) {
    $.get("/abc", function(data){
      $("#soqlContent").html(JSON.stringify(data));
    });
    /*
    beginRefresh();
    const action = $(this).attr("action");
    const options = $.getAjaxOptions(action, GET, {}, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(afterRefreshMetadata, onRefreshError, null);
    $.executeAjax(options, callbacks);    
    */
  });

  const afterRefreshMetadata = (json) => {
    $(document).trigger("afterRefreshMetadataTypes", [{result: json.result}]);
    endRefresh();
  }

  //------------------------------------------------
  // Refresh misc
  //------------------------------------------------
  const beginRefresh = () => $("#overlay").show();
  const endRefresh = () => $("#overlay").hide();

  const onRefreshError = (json) =>{
    alert(json.error);
  }

  //------------------------------------------------
  // Locale
  //------------------------------------------------
  const reflectUserLocalOption = () => {
    const userLocalOption = $("#userLocalOption").text();
    $('.locale-options li a').each(function() {
        if (userLocalOption === $(this).attr("locale-option")){
          $(this).addClass("checkmark");
          $("#mainArea").attr("current-locale-option", userLocalOption);
          return;
        }
     
      });
  }

  $(".locale-options a").on("click", function(e){
    if ($(this).hasClass("checkmark")){
      return false;
    }

    $(".locale-options a").not(this).removeClass("checkmark");
    $(this).addClass("checkmark");

    $("#mainArea").attr("current-locale-option", $(this).attr("locale-option"));

    return false;

  });


  //------------------------------------------------
  // page load actions
  //------------------------------------------------
  //reflectUserLocalOption();
  //prepareSObjectLists();
  //prepareMetadataTypes();
};

$(document).ready(soql);
$(document).on("page:load", soql);
