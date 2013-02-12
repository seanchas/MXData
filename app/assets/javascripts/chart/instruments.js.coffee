##= require d3.v3

$               = jQuery
scope           = @mx.chart

metadata        = undefined


tickers_cache       = {}
securities_cache    = {}


default_precision_key           = 'DECIMALS'
default_render_debounce_timeout = .250 * 1000


colors = d3.scale.category20().domain(d3.range(20))


actions =
    order: 'on off remove'.split(' ')
    ru:
        on:     'Показывать на графике'
        off:    'Не показывать на графике'
        remove: 'Убрать с графика'
    en:
        on:     'Show on chart'
        off:    'Don\'t show on chart'
        remove: 'Remove from chart'



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
    
    actions.order.forEach (action) ->
        
        $('<a>')
            .attr('href', '#')
            .attr('data-action', action)
            .html(actions[mx.I18n.locale][action])
            .appendTo(html)
            .wrap('<li>')
    
    html


colorize_tickers = (html) ->
    $('li.ticker > a.dropdown-toggle', html).each (i) ->
        item    = $(@)
        offset  = if item.parent().hasClass('off') then 1 else 0
        
        item.css('color', colors(i * 2 + offset))
        item.find('> .caret').css('border-top-color', colors(i * 2 + offset))


widget = (options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0
    
    deferred    = new $.Deferred
    
    html        = $('<ul>').addClass('nav nav-pills chart-tickers')
    
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
        html.empty()
        
        tickers.forEach (ticker) ->
            item = $('<li>')
                .addClass('dropdown ticker')
                .appendTo(html)
            
            $('<a>')
                .addClass('dropdown-toggle')
                .attr('href', '#')
                .attr('data-toggle', 'dropdown')
                .html(securities_cache[ticker].SECID + ': ' + tickers_cache[ticker][0].boardgroup.title)
                .append($('<span>').addClass('caret'))
                .appendTo(item)
            
            item.append render_dropdown_menu()
        
        colorize_tickers(html)
        
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


$(document).on 'click', '.chart-tickers a[data-action]', (event) ->
    event.stopPropagation()
    event.preventDefault()
    
    el = $(@)

    el.parent().click()
    
    switch el.data('action')
        when 'remove'
            1
        when 'on', 'off'
            el.closest('li.dropdown').toggleClass('off')
            colorize_tickers(el.closest('ul.chart-tickers'))
