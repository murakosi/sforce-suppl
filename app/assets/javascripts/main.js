const mains = function() {

  let selectedAnchor = null;
  let targetDiv = null;
  let anchorObject = null;  
  const loadedPartials = {};
  const defaultDetatype = "";
  const defaultContentType = null;

  $("#menus").on("click", "a", function(e) {
    if ($("#dropdown-menu").is(":visible")) {
      $("#userInfoButton").trigger("click");
    }
      
    const clickedAnchor = $(this).prop("id");

    if (selectedAnchor === clickedAnchor) {
      return false;
    }

    e.preventDefault();
    e.stopPropagation();
    selectedAnchor = clickedAnchor;
    targetDiv = $(this).attr("loadTarget");
    anchorObject = this;

    const action = $(this).attr('action');

    if (loadedPartials[selectedAnchor] || action === "") {
      changeDisplayDiv(selectedAnchor);      
      return false;
    }
    
    $.get(action, function(result){
      loadPartials(result);
    });
  });
  
  const loadPartials = (json) => {
    loadedPartials[selectedAnchor] = true;
    $("div" + json.target).html(json.content);
    changeDisplayDiv(selectedAnchor);
    if (json.status !== 200) {
      createErrorDiv(json.error);
    }
  };

  const changeAnchorClass = (target) => {
    $(".menus").not(target).removeClass("displayed");

    if ($(target).hasClass("displayed")) {
      $(target).removeClass("displayed");
    } else {
      $(target).addClass("displayed");
    }
  };

  const changeDisplayDiv = (target) => {
    if ($(anchorObject).hasClass("nochange")) {
      return;
    }
    
    changeAnchorClass(anchorObject);

    $("div#mainArea").prop("class", target);

    if (target === "metadata") {
      const targetSelect2 = "div#metadataArea .selectlist";
      $(targetSelect2).select2({
        dropdownAutoWidth : true,
        width: 'resolve',
        containerCssClass: ':all:',
        placeholder: "Select a metadata type",
        allowClear: true
        });
    }
    
    $(document).trigger("displayChange", [{targetArea: target + "Area"}]);
  };

  const refreshSObjectLists = () => {
    $(".sobject-select-list").select2({
        dropdownAutoWidth : true,
        width: 'element',
        containerCssClass: ':all:',
        placeholder: "Select an sObject",
        allowClear: true
        });
  };

  $("a#refreshDescribe").on("click", function(e) {
    return false;
  });
  
  refreshSObjectLists();
      
  $("a#soqlexecuter").trigger("click");
};

$(document).ready(mains);
$(document).on('page:load', mains);
