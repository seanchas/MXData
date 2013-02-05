root    = @
scope   = root['mx']['data']


$       = jQuery


metadata        = undefined


reload_timeout  = 2 * 1000


locales =
    buy:
        ru: 'Покупка'
        en: 'Buy'
    sell:
        ru: 'Продажа'
        en: 'Sell'


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
        .html(locales.buy[mx.locale()])
        .appendTo(header_row)
    
    $('<td>')
        .appendTo(header_row)
    
    $('<td>')
        .addClass('sell')
        .attr('colspan', 2)
        .html(locales.sell[mx.locale()])
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
    

widget = (ticker, options = {}) ->

    deferred    = new $.Deferred

    after_render_callbacks   = new $.Callbacks
    
    [board, id] = ticker.split(':')
    
    metadata    ?= mx.data.metadata()
    ready       = $.when metadata

    html        = undefined
    access      = undefined
    error       = undefined
    

    [].concat(options.after_render).forEach after_render_callbacks.add if options.after_render?

    
    reload = ->
        return _.delay(reload, reload_timeout) if html?.is(':hidden')
        
        orderbook = mx.iss.orderbook(board.engine.name, board.market.name, board.id, id, { force: true })

        orderbook.then ->
            
            html        = undefined
            error       = undefined

            orderbook   = orderbook.result
            access      = orderbook['x-marker']
            html        = render(orderbook.data)    unless  orderbook.error? or orderbook.data.length == 0
            error       = orderbook.error           if      orderbook.error?

            _.delay reload, reload_timeout
    
            after_render_callbacks.fire()

            deferred.resolve()
            

    ready.then ->
        
        board   = metadata.board(board)

        reload()



    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error
    



$.extend scope,
    security_info_orderbook: widget
