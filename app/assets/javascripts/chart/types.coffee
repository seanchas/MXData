$               = jQuery
scope           = @mx.chart



widget = (options = {}) ->
    
    container   = $(options.container) ; container = undefined if container.length == 0

    
    type        = options.default
    
    
    type: ->
        type

    container:  (_container = undefined) ->
        if arguments.length > 0
            container = $(_container)
            container = undefined if container.length == 0
        container


$.extend scope,
    types_widget: widget
