##= require d3.v3

$               = jQuery
scope           = @mx.chart

metadata        = undefined


tickers_cache       = {}
securities_cache    = {}


default_precision_key           = 'DECIMALS'


colors = d3.scale.category20().domain(d3.range(20))


actions =
    order: 'on off remove'.split(' ')
    classes: ['icon-eye-open', 'icon-eye-close', 'icon-remove']
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



render_tickers = (html, tickers) ->
    views = html.children('li.ticker')
    
    $.each tickers, (i, ticker) ->
        view = views.filter (i) -> $(views[i]).data('ticker') == ticker
        view = render_ticker(ticker) if view.length == 0
        html.append(view) if view?
    
    views = html.children('li.ticker')
    
    views.each (i, view) ->
        view = $(view) ; view.remove() if tickers.indexOf(view.data('ticker')) < 0
    
    


render_ticker = (ticker) ->
    return unless securities_cache[ticker]? and tickers_cache[ticker]?
    
    view = $('<li>')
        .addClass('dropdown ticker')
        .data('ticker', ticker)
    
    render_ticker_link(ticker)
        .appendTo(view)
    
    render_ticker_dropdown_menu()
        .appendTo(view)
    
    view


render_ticker_link = (ticker) ->
    $('<a>')
        .addClass('dropdown-toggle')
        .attr('href', '#')
        .attr('data-toggle', 'dropdown')
        .html(securities_cache[ticker].SECID + ': ' + tickers_cache[ticker][0].boardgroup.title)
        .append($('<span>').addClass('caret'))


render_ticker_dropdown_menu = ->
    ich.chart_instruments_dropdown_menu()


reorder_tickers = (html, tickers) ->
    views = html.children('li.ticker')
    
    $.each tickers, (i, ticker) ->
        views.filter((i) -> $(views[i]).data('ticker') == ticker).appendTo(html)
        


set_tickers_states = (html, off_tickers) ->
    views = html.children('li.ticker').removeClass('off')

    $.each off_tickers, (i, ticker) ->
        views.filter((i) -> $(views[i]).data('ticker') == ticker).addClass('off')
        



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
    off_tickers = []


    ticker_present = (ticker) ->
        [board, id] = ticker.split(':') ; board = metadata.board(board)
        tickers.some (item) -> [b, i] = tickers_cache[item] ; i == id and b.engine.name == board.engine.name and b.market.name == board.market.name


    add_ticker  = (ticker) ->
        return if ticker_present(ticker)
        
        tickers.push(ticker)

        [board, id] = tickers_cache[ticker] ?= prepare_ticker(ticker)

        security    = securities_cache[ticker] ? mx.iss.security_marketdata(board.engine.name, board.market.name, board.id, id)
        columns     = mx.iss.security_marketdata_columns(board.engine.name, board.market.name)
        
        $.when(security, columns).then ->
            securities_cache[ticker]   ?= prepare_record(security.result.data.security, columns.result.data)
            render()


    remove_ticker = (ticker) ->
        ticker_index = tickers.indexOf(ticker) ; return if ticker_index < 0
        tickers.splice(ticker_index, 1)
        render()
    
    
    toggle_ticker = (ticker) ->
        ticker_index        = tickers.indexOf(ticker) ; return if ticker_index < 0
        off_ticker_index    = off_tickers.indexOf(ticker)

        if off_ticker_index < 0
            off_tickers.push(ticker)
        else
            off_tickers.splice(off_ticker_index, 1)
        
        render()



    render = ->
        if container?
            render_tickers(html, tickers)
            reorder_tickers(html, tickers)
            set_tickers_states(html, off_tickers)
            colorize_tickers(html)
        
        if container? and !$.contains(container, html)
            container.append(html)

            html.sortable
                tolerance: 'pointer'
                start: (event, ui) ->
                    ui.helper.removeClass('open').blur()

                update: ->
                    tickers = html.children('li.ticker').map((i, view) -> $(view).data('ticker')).get()
                    render()
        
        deferred.resolve()


    ready.then ->
        
        add_ticker(options.ticker) if options.ticker?
        
        html.on 'chart:ticker:on chart:ticker:off', (event, ticker) -> toggle_ticker ticker

        html.on 'chart:ticker:remove', (event, ticker) -> remove_ticker ticker
        
        render()
    
    
    deferred.promise
        tickers: ->         tickers
        add_ticker:         add_ticker
        remove_ticker:      remove_ticker



$.extend scope,
    instruments_widget: widget


##
## Data API
##

$(document).on 'click', '.chart-tickers a[data-action]', (event) ->
    event.stopPropagation()
    event.preventDefault()
    
    el          = $(@)
    action      = el.data('action')
    ticker      = el.closest('li.ticker').data('ticker')
    container   = el.closest('ul.chart-tickers')

    container.trigger("chart:ticker:#{action}", ticker)

    el.parent().click()
    
