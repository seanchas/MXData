root    = @
scope   = root['mx']['data']

$       = jQuery


metadata    = mx.data.metadata()


widget = (container, ticker) ->
    container   = $(container) ; return if container.length == 0

    ready       = $.when(metadata)

    render = ->
        container.empty()
        container.append(ich.table_information_row)


    ready.then ->
        render()
        
        board = metadata.board(_.first(ticker.split(':')))
        
        $(container).on 'click', 'li.remove_ticker span', ->
            $(window).trigger "global:table:security:remove:#{board.engine.name}:#{board.market.name}", { ticker: ticker }
            

        $(container).on 'click', 'li.add_to_chart span', ->
            $(window).trigger 'security:to:chart', ticker
            

        $(container).on 'click', 'li.remove_from_chart span', ->
            $(window).trigger 'security:from:chart', ticker
            
    
    
$.extend scope,
    table_information_row: widget
