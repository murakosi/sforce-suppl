const mains = function() {

  let _selectedAnchor = null;
  let _anchorObject = null;  
  const DEFAULT_DETA_TYPE = "";
  const DEFAULT_CONTENT_TYPE = null;

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

  const refreshSObjectLists = () => {
    $(".sobject-select-list").select2({
        dropdownAutoWidth : true,
        width: "element",
        containerCssClass: ":all:",
        placeholder: "Select an sObject",
        allowClear: true
        });
  };

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

  $("a#refreshDescribe").on("click", function(e) {
    
  });
  
  refreshSObjectLists();
  refreshMetadataTypes();

};

$(document).ready(mains);
$(document).on("page:load", mains);
