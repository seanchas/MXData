##= require jquery


root            = @
root.shared    ?= {}
scope           = root.shared


widget = (container) ->
    container = $(container) ; return if container.length == 0
    
    


$.extend scope,
    tabs: widget
