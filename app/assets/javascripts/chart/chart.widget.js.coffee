$               = jQuery
scope           = @mx.chart


widget = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = undefined
    
    ready       = $.when true
    
    
    instruments = scope.instruments_widget(options)


    ready.then ->
        deferred.resolve()
    
    
    deferred.promise()



$.extend scope,
    widget: widget
