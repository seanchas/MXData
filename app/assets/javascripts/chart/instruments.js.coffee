$               = jQuery
scope           = @mx.chart

metadata        = undefined


tickers_cache       = {}
securities_cache    = {}


default_precision_key           = 'DECIMALS'
default_render_debounce_timeout = .250 * 1000


prepare_ticker = (ticker) ->
    [board, id] = ticker.split(':') ; [metadata.board(board), id]


prepare_record = (record, columns) ->
    columns             = columns.hash('name')
    default_precision   = record[default_precision_key]
    precisions          = {}
    
    Object.keys(record).forEach (key) ->
        column = columns[key]

        if column? and column.type == 'number'
            value           = parseFloat(record[key]) || undefined
            precisions[key] = column.precision ? default_precision
            record[key]     = parseFloat(value.toFixed(precisions[key])) if value?
    
    record.precisions = precisions
    
    record


widget = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = undefined
    
    metadata   ?= mx.data.metadata()
    
    ready       = $.when metadata
    
    tickers     = []


    render_debounce_timeout = default_render_debounce_timeout


    add_ticker  = (ticker) ->
        return unless tickers.indexOf(ticker) < 0
        
        tickers.push(ticker)

        [board, id] = tickers_cache[ticker] ?= prepare_ticker(ticker)

        security    = mx.iss.security_marketdata(board.engine.name, board.market.name, board.id, id)
        columns     = mx.iss.security_marketdata_columns(board.engine.name, board.market.name)
        
        $.when(security, columns).then ->
            securities_cache[ticker]   ?= prepare_record(security.result.data.security, columns.result.data)
            render()


    remove_ticker = (ticker) ->
        ticker_index = tickers.indexOf(ticker) ; return if ticker_index < 0
        tickers.splice(ticker_index, 1)
        render()



    render = ->
        console.log 'rendered'
        deferred.resolve()


    render = _.debounce render, render_debounce_timeout


    ready.then ->
        
        add_ticker(options.ticker) if options.ticker?
        render()
    
    
    deferred.promise
        tickers: -> tickers



$.extend scope,
    instruments_widget: widget
