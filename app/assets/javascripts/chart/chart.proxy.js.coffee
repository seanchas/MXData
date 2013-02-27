$               = jQuery
scope           = @mx.chart


proxy = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = undefined
    
    ready       = $.when mx.data.metadata()
    
    ready.then ->
        deferred.resolve()
    
    
    deferred.promise()



$.extend scope,
    proxy: proxy
