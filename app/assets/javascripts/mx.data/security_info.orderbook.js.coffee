root    = @
scope   = root['mx']['data']


$       = jQuery


metadata        = mx.data.metadata()


reload_timeout  = 15 * 1000


render = (data) ->
    table       = $('<table>')
        .html('<thead></thead><tbody></tbody>')
    
    table_head  = $('thead', table)
    table_body  = $('tbody', table)
    
    
    header_row  = $('<tr>')
        .appendTo(table_head)
    
    $('<td>')
        .addClass('buy')
        .attr('colspan', 2)
        .html('Покупка')
        .appendTo(header_row)
    
    $('<td>')
        .appendTo(header_row)
    
    $('<td>')
        .addClass('sell')
        .attr('colspan', 2)
        .html('Продажа')
        .appendTo(header_row)
    
    data.max_quantity = _.chain(data).pluck('QUANTITY').max().value()
    
    _.each data, render_table_body_row, table_body
    
    table


render_table_body_row = (record, index, data) ->
    row = $('<tr>')
        .toggleClass('buy', record.BUYSELL == 'B')
        .toggleClass('sell', record.BUYSELL == 'S')
        .appendTo(@)
    
    buy_quantity = $('<td>')
        .addClass('buy quantity')
        .appendTo(row)
    
    buy_bar = $('<td>')
        .addClass('buy bar')
        .appendTo(row)
    
    price = $('<td>')
        .addClass('price')
        .html(scope.utils.number_with_precision(record.PRICE, { precision: record.DECIMALS }))
        .appendTo(row)
    
    sell_bar = $('<td>')
        .addClass('sell bar')
        .appendTo(row)
    
    sell_quantity = $('<td>')
        .addClass('sell quantity')
        .appendTo(row)
    
    [quantity, bar] = if record.BUYSELL == 'B' then [buy_quantity, buy_bar] else [sell_quantity, sell_bar]
    
    quantity.html(scope.utils.number_with_delimiter(record.QUANTITY))
    
    $('<div>')
        .css('width', (100 * record.QUANTITY / data.max_quantity) + '%')
        .appendTo(bar)
    
    row
    

widget = (ticker) ->

    deferred    = new $.Deferred
    
    engine      = undefined
    market      = undefined
    [board, id] = ticker.split(':')
    
    ready       = $.when metadata

    html        = undefined
    access      = undefined
    error       = undefined

    
    reload = ->
        orderbook = mx.iss.orderbook(engine.name, market.name, board.id, id, { force: true })

        orderbook.then ->
            
            html        = undefined
            error       = undefined

            orderbook   = orderbook.result
            access      = orderbook['x-marker']
            html        = render(orderbook.data)    unless  orderbook.error?
            error       = orderbook.error           if      orderbook.error?

            $(window).trigger "security-info:orderbook:loaded:#{ticker}"

            _.delay reload, reload_timeout
    

    ready.then ->
        
        board   = metadata.board(board)
        engine  = board.engine
        market  = board.market

        reload()

        deferred.resolve()


    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error
    



$.extend scope,
    security_info_orderbook: widget
