$               = jQuery
scope           = @mx.chart



render = ->
    ich.chart()



proxy = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = undefined
    
    types_widget    = scope.types_widget
             default: 'line'

    ready       = $.when mx.data.metadata()
    
    ready.then ->
        
        html = render().appendTo(container) if container?
        
        deferred.resolve()
    
    
    deferred.promise()



$.extend scope,
    proxy: proxy