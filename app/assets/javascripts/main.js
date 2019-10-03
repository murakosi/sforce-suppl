const mains = function() {

  let _selectedAnchor = null;
  let _targetDiv = null;
  let _anchorObject = null;  
  const _loadedPartials = {};
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

    e.preventDefault();
    e.stopPropagation();
    _selectedAnchor = clickedAnchor;
    _targetDiv = $(this).attr("loadTarget");
    _anchorObject = this;

    const action = $(this).attr("action");

    if (_loadedPartials[_selectedAnchor] || action === "") {
      changeDisplayDiv(_selectedAnchor);      
      return false;
    }
    
    $.get(action, (result) => loadPartials(result));

  });
  
  const loadPartials = (json) => {
    _loadedPartials[_selectedAnchor] = true;
    $("div" + json.target).html(json.content);
    changeDisplayDiv(_selectedAnchor);
    if (json.status !== 200) {
      createErrorDiv(json.error);
    }
  };

  const changeDisplayDiv = (target) => {
    if ($(_anchorObject).hasClass("nochange")) {
      return;
    }
    
    changeAnchorClass(_anchorObject);

    $("div#mainArea").prop("class", target);

    if (target === "metadata") {
      const targetSelect2 = "div#metadataArea .selectlist";
      $(targetSelect2).select2({
        dropdownAutoWidth : true,
        width: "resolve",
        containerCssClass: ":all:",
        placeholder: "Select a metadata type",
        allowClear: true
        });
    }
    
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

  $("a#refreshDescribe").on("click", function(e) {
    
  });
  
  refreshSObjectLists();

};

$(document).ready(mains);
$(document).on("page:load", mains);
