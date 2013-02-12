##= require d3.v3

$               = jQuery
scope           = @mx.chart

metadata        = undefined


tickers_cache       = {}
securities_cache    = {}


default_precision_key           = 'DECIMALS'
default_render_debounce_timeout = .250 * 1000


colors = d3.scale.category10()


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


render_dropdown_menu = ->
    html = $('<ul>')
        .addClass('dropdown-menu')
    
    $('<a>')
        .attr('href', '#')
        .attr('data-action', 'on')
        .html('Показывать на графике')
        .appendTo(html)
        .wrap('<li />')
    
    $('<a>')
        .attr('href', '#')
        .attr('data-action', 'off')
        .html('Не показывать на графике')
        .appendTo(html)
        .wrap('<li />')
    
    $('<a>')
        .attr('href', '#')
        .attr('data-action', 'remove')
        .html('Удалить с графика')
        .appendTo(html)
        .wrap('<li />')
    
    html


widget = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = undefined
    
    metadata   ?= mx.data.metadata()
    
    ready       = $.when metadata
    
    tickers     = []


    render_debounce_timeout = default_render_debounce_timeout


    ticker_present = (ticker) ->
        [board, id] = ticker.split(':') ; board = metadata.board(board)
        tickers.some (item) -> [b, i] = tickers_cache[item] ; i == id and b.engine.name == board.engine.name and b.market.name == board.market.name


    add_ticker  = (ticker) ->
        console.log 'adding ' + ticker
        
        return if ticker_present(ticker)
        
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
        html = $('<ul>')
            .addClass('nav nav-pills chart-tickers')
        
        tickers.forEach (ticker) ->
            item = $('<li>')
                .addClass('dropdown')
                .appendTo(html)
            
            $('<a>')
                .addClass('dropdown-toggle')
                .attr('href', '#')
                .attr('data-toggle', 'dropdown')
                .css('color', colors(tickers.indexOf(ticker)))
                .html(securities_cache[ticker].SECID + ': ' + tickers_cache[ticker][0].boardgroup.title)
                .append($('<span>').addClass('caret').css('border-top-color', colors(tickers.indexOf(ticker))))
                .appendTo(item)
            
            item.append render_dropdown_menu()
        
        container.html(html) if container?
        
        deferred.resolve()


    render = _.debounce render, render_debounce_timeout


    ready.then ->
        
        add_ticker(options.ticker) if options.ticker?
        render()
    
    
    deferred.promise
        tickers: -> tickers
        add_ticker: add_ticker



$.extend scope,
    instruments_widget: widget
