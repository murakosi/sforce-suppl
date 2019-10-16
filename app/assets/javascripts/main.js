const mains = function() {

  let _selectedAnchor = null;
  let _anchorObject = null;  
  const DEFAULT_DATA_TYPE = "";
  const DEFAULT_CONTENT_TYPE = null;

  //------------------------------------------------
  // Menu list
  //------------------------------------------------
  $("#menus").on("click", "a", function(e) {
    if ($("#dropdown-menu").is(":visible")) {
      $("#userInfoButton").trigger("click");
    }
      
    const clickedAnchor = $(this).prop("id");

    if (_selectedAnchor === clickedAnchor) {
      return false;
    }

    _selectedAnchor = clickedAnchor;
    _anchorObject = this;

    changeDisplayDiv(_selectedAnchor);      
    return false;    

  });
  
  const changeDisplayDiv = (target) => {
    if ($(_anchorObject).hasClass("nochange")) {
      return;
    }
    
    changeAnchorClass(_anchorObject);

    $("div#mainArea").prop("class", target);
    
    $(document).trigger("displayChange", [{targetArea: target + "Area"}]);
  };

  const changeAnchorClass = (target) => {
    $(".menus").not(target).removeClass("displayed");

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
        placeholder: "Select an sObject",
        allowClear: true
        });
  };

  $("#refreshSObjects").on("click", function(e) {
    beginRefresh();
    const action = "refresh_sobjects";
    const method = "get";
    const options = $.getAjaxOptions(action, method, {}, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(onRefreshSObjectsDone, onRefreshError, null);
    $.executeAjax(options, callbacks);
  });

  const onRefreshSObjectsDone = (json) => {
    $(document).trigger("afterRefreshSObjects", [{result: json.result}]);
    endRefresh();
  }

  //------------------------------------------------
  // Metadata
  //------------------------------------------------
  const prepareMetadataTypes = () => {
    const targetSelect2 = "div#metadataArea .selectlist";
    $(targetSelect2).select2({
      dropdownAutoWidth : true,
      width: "auto",
      containerCssClass: ":all:",
      placeholder: "Select a metadata type",
      allowClear: true
      });    
  }

  $("#refreshMetadata").on("click", function(e) {
    beginRefresh();
    const action = "refresh_metadata";
    const method = "get";
    const options = $.getAjaxOptions(action, method, {}, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE, false);
    const callbacks = $.getAjaxCallbacks(onRefreshMetadataDone, onRefreshError, null);
    $.executeAjax(options, callbacks);    
  });

  const onRefreshMetadataDone = (json) => {
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
  const setDefaultLocalOption = () => {
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

  setDefaultLocalOption();
  prepareSObjectLists();
  prepareMetadataTypes();

};

$(document).ready(mains);
$(document).on("page:load", mains);
