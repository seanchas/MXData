root    = @
scope   = root['mx']['data']

$       = jQuery


metadata    = undefined


widget = (container, ticker) ->
    container   = $(container) ; return if container.length == 0


    metadata   ?= mx.data.metadata()
    
    ticker_aux  = scope.table_ticker_aux(ticker)
    
    ready       = $.when(metadata, ticker_aux)


    render = ->
        container.empty()
        container.append(ticker_aux.html())


    ready.then ->

        render()
        
            
    
    
$.extend scope,
    table_information_row: widget
