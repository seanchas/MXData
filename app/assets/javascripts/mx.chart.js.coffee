##= require mx.iss

$               = jQuery
root            = @
root.mx        ?= {}
root.mx.chart  ?= {}
scope           = root.mx.chart



widget = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = undefined
    
    ready       = $.when true


    ready.then ->
        deferred.resolve()
    
    
    deferred.promise()



$.extend scope,
    widget: widget
