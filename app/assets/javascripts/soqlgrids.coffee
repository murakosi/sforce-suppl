
soqlgrids = ->

  selectedAnchor = null

  
  #targetSelect2 = "div#soqlGridsArea .sobjects"
  #$(targetSelect2).select2({
  #  dropdownAutoWidth : true,
  #  width: 'resolve',
  #  containerCssClass: ':all:'
  #  })

$(document).ready(soqlgrids)
$(document).on('page:load', soqlgrids)
