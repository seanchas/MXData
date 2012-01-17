root    = @
scope   = root['mx']['data']
$       = jQuery


query_param_threshold = 3


widget = (element, options = {}) ->
    element = $(element); return unless _.size(element) > 0
    
    search_request  = null
    
    query_field     = $("input[type=search]", element)
    query_param     = ""
    
    onchange = (event) ->
    
    query_field.on "keyup", onchange
    

$.extend scope,
    quote_search: widget
