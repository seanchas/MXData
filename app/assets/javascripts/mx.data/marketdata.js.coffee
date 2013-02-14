root    = @
scope   = root['mx']['data']
$       = jQuery



widget = (element, options = {}) ->
    element = $(element); return unless _.size(element) > 0

    filters_data_source = mx.iss.marketdata_filters("#{options.engine}:#{options.market}");
    
    $.when(
        filters_data_source
    ).then (filters) ->
        1
    
    {}



$.extend scope,
    marketdata_table: widget
