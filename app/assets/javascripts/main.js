const mains = function() {

  let _selectedAnchor = null;
  let _anchorObject = null;  
  const DEFAULT_DATA_TYPE = "";
  const DEFAULT_CONTENT_TYPE = null;

  //
  // Menu list
  //
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

  //
  //
  //
  const refreshSObjectLists = () => {
    $(".sobject-select-list").select2({
        dropdownAutoWidth : true,
        width: "element",
        containerCssClass: ":all:",
        placeholder: "Select an sObject",
        allowClear: true
        });
  };

  $("#refreshSObjects").on("click", function(e) {
    const action = "refresh_sobjects";
    const method = "get";
    const options = $.getAjaxOptions(action, method, null, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
    const callbacks = $.getAjaxCallbacks(onRefreshSObjectsDone, onRefreshError, null);
    $.executeAjax(options, callbacks);
  });

  const onRefreshSObjectsDone = (json) => {
    $(document).trigger("afterRefreshSObjects", [{result: json.result}]);
  }

  const refreshMetadataTypes = () => {
    const targetSelect2 = "div#metadataArea .selectlist";
    $(targetSelect2).select2({
      dropdownAutoWidth : true,
      width: "resolve",
      containerCssClass: ":all:",
      placeholder: "Select a metadata type",
      allowClear: true
      });    
  }

  $("#refreshMetadata").on("click", function(e) {
    const action = "refresh_metadata";
    const method = "get";
    const options = $.getAjaxOptions(action, method, null, DEFAULT_DATA_TYPE, DEFAULT_CONTENT_TYPE);
    const callbacks = $.getAjaxCallbacks(onRefreshMetadataDone, onRefreshError, null);
    $.executeAjax(options, callbacks);    
  });

  const onRefreshMetadataDone = (json) => {
    $(".sobject-select-list").html(json.sobject_list);
    refreshSObjectLists();
    $(document).trigger("afterRefreshSObjects", []);
  }

  const onRefreshError = (json) =>{
    console.log(json);
  }

  $(".locale-options a").on("click", function(e){
    if ($(this).hasClass("checkmark")){
      return false;
    }

    $(".locale-options a").not(this).removeClass("checkmark");
    $(this).addClass("checkmark");

    return false;

  });

  refreshSObjectLists();
  refreshMetadataTypes();

};

$(document).ready(mains);
$(document).on("page:load", mains);
