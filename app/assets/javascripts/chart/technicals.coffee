$               = jQuery
scope           = @mx.chart

metadata        = undefined


widget = (options = {}) ->
    
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred

    metadata   ?= mx.data.metadata()
    html        = undefined
    technicals  = []
    
    ready       = $.when metadat
    
    

    render = ->
        if container?
            $.noop
            
            container.append(html) unless $.contains(container, html)
        
        deferred.resolve()

    
    
    ready.then ->

        render.resolve()


    
    deferred.promise
        technicals: -> technicals
        html:       -> html


$.extend scope,
    technicals_widget: widget
