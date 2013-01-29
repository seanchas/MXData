root    = @
scope   = root['mx']['data']

$       = jQuery

cache   = kizzy('data.table')


default_filter  = 'preview'


# main container

make_table_container_view = (wrapper, engine, market) ->
    container = ich.table({ engine: engine, market: market }).appendTo(wrapper).hide()


# table head columns

render_table_head_columns = (container, columns, options = {}) ->
    cells = container.children()
    
    for column in columns

        cell = _.first(cell for cell in cells when $(cell).data('id') == column.id)
        
        unless cell?
            cell = render_table_head_column_cell(column, options)
            container.append(cell)
    
    ids = _.pluck(columns, 'id')
    
    for cell in cells
        cell = $(cell)
        cell.remove() unless _.include(ids, cell.data('id'))
    
    container


render_table_head_column_cell = (column, options = {}) ->
    ich.table_column_cell({ column: column })
        .toggleClass('sortable', !!column.is_ordered)


render_table_head_columns_filter_cell = (container, columns, view, options = {}) ->
    cell = _.first($('td', container))
    
    unless cell
        cell = $('<td>')
            .append(view)
            .appendTo(container)
    
    cell = $(cell)
    
    cell.attr('colspan', _.size(columns))
    
    container


# table body rows

render_table_body_rows = (container, records, columns, options = {}) ->
    rows = container.children('tr.ticker')
    
    for record in records
        
        record.ticker = [record.BOARDID, record.SECID].join(':')
        
        row = _.first(row for row in rows when $(row).data('id') == record.ticker)
        
        unless row?
            row = render_table_body_row(record, columns, options)
            container.append(row)
        
        row = $(row)
        
        render_table_body_row_cells(row, record, columns, options)
        
        if information_row = row.data('information-row')
            $('> td', information_row).attr('colspan', row.children().length)
    

    tickers = _.pluck(records, 'ticker')
    

    for row in rows
        row = $(row)
        remove_row(row) unless _.include(tickers, row.data('id'))
    
    container
            

remove_row = (row) ->
    if information_row = row.data('information-row')
        information_row.remove()
    row.remove()


render_table_body_row = (record, columns, options = {}) ->
    row = $('<tr>')
        .addClass('ticker')
        .data({ id: [record.BOARDID, record.SECID].join(':') })
    
    row


render_table_body_row_cells = (row, record, columns, options = {}) ->
    cells = row.children()
    
    for column in columns

        cell = _.first(cell for cell in cells when $(cell).data('id') == column.id)
        
        unless cell?
            cell = render_table_body_row_cell(record, column, options)
            row.append(cell)
        
        cell = $(cell)
        
        render_table_body_row_cell_content(cell, record, column, options)
        
    ids = _.pluck(columns, 'id')
    
    for cell in cells
        cell = $(cell)
        cell.remove() unless _.include(ids, cell.data('id'))

    row


render_table_body_row_cell = (record, column, options = {}) ->
    cell = $('<td>')
        .data({ id: column.id })
        .addClass(column.type)

    cell


render_table_body_row_cell_content = (cell, record, column, options = {}) ->
    value               = record[column.name]
    value_for_render    = scope.utils.render_marketdata_record_value(column.name, record, column)
    trend               = record.trends[column.name]
    
    if trend?
        cell.toggleClass('up', trend.value > 0)
        cell.toggleClass('down', trend.value < 0)
        cell.toggleClass('trend_by_self', trend.self)
        cell.toggleClass('trend_by_other', !trend.self)
    
    cell
        .data({ value: value })
        .html($('<span>').html(value_for_render || '&mdash;'))
    
    cell


colorize_table_body_cell_changes = (container) ->
    cells = $('.trend_by_other', container)
    
    for cell in cells

        cell            = $(cell)
        cell_content    = $('span', cell)
        
        previous_value              = cell.data('previous_value')
        current_value               = cell.data('value')
        
        previous_value_for_render   = cell.data('previous_value_for_render')
        current_value_for_render    = cell_content.html()
        
        cell.data('previous_value', current_value)
        cell.data('previous_value_for_render', current_value_for_render)
        
        if current_value_for_render? and previous_value_for_render?

            constant        = ''
            volatile        = ''
            
            sign            = if current_value > previous_value then 'up' else if current_value < previous_value then 'down' else undefined
            
            if current_value_for_render.length == previous_value_for_render.length
                
                offset = 0
                for i in [0 .. current_value_for_render.length - 1]
                    break if current_value_for_render[i] != previous_value_for_render[i] ; ++offset
                
                constant    = current_value_for_render.slice(0, offset)
                volatile    = current_value_for_render.slice(offset)
                
            else
                volatile = current_value_for_render
            
            cell_content.html(constant)
            cell_content.append($('<em>').addClass(sign).html(volatile))




toggle_ticker_information = (row) ->
    information_row = row.data('information-row') ? render_information_row(row)
    information_row.toggle()



render_information_row = (row) ->
    cells = $('td', row)
    
    result = $('<tr>')
        .addClass('info')
        .toggleClass('chart', row.hasClass('chart'))
        .append(
            $('<td>')
                .attr('colspan', cells.length)
                .html('information row')
        )
        .insertAfter(row)
        .hide()
    
    row.data('information-row', result)
    result.data('widget', mx.data.table_information_row(_.first(result.children()), row.data('id')))
    
    result


process_chart_tickers = (container, tickers) ->
    rows = $('tr.ticker', container)

    _.each rows, hide_chart_state

    chart_rows = _.select(rows, (row) -> _.include(tickers, $(row).data('id')))
    
    _.each chart_rows, (row) ->
        show_chart_state row
       

change_chart_state = (row, state) ->
    row = $(row)
    
    row.toggleClass('chart', state)

    if information_row = row.data('information-row')
        information_row.toggleClass('chart', row.hasClass('chart'))


show_chart_state = (row) ->
    change_chart_state(row, true)
    
hide_chart_state = (row) ->
    change_chart_state(row, false)



colorize_rows = (table) ->
    rows = $('tr.ticker', table)
    
    rows
        .removeClass('even')
        .removeClass('odd')
    
    rows.filter(':even').addClass('even')
    rows.filter(':odd').addClass('odd')



widget = (wrapper, engine, market) ->
    wrapper = $(wrapper) ; return if _.isEmpty(wrapper)
    
    deferred    = new $.Deferred
    
    cache_key   = [engine.name, market.name].join(':')
    
    table_container_view    = make_table_container_view(wrapper, engine, market)
    table_view              = $('table', table_container_view)
    table_head_view         = $('thead', table_view)
    table_body_view         = $('tbody', table_view)
    columns_filter_view     = $('div.columns_filter_wrapper', table_container_view)
    
    
    columns_filter          = scope.table_columns_filter(columns_filter_view, engine.name, market.name)


    filters_source          = mx.iss.marketdata_filters(engine.name, market.name)
    columns_source          = mx.iss.marketdata_columns(engine.name, market.name)

    securities_source       = undefined
    marketdata_source       = undefined

    records_source          = undefined

    ready_for_render        = $.when columns_source, filters_source, columns_filter
    
    tickers                 = []
    chart_tickers           = []
    
    
    sort_in_progress        = false
    active_sortable_index   = 0
    
    prepared_columns        = undefined
    
    reload_timer            = undefined
    refresh_timer           = undefined
    
    securities_data_version = 0
    marketdata_data_version = 0
    
    securities_data         = undefined
    marketdata_data         = undefined
    
    
    columns_sorter_is_active    = false
    
    access_marker           = 'denied'
    
    
    # tickers
    
    add_ticker = (ticker) ->
        unless _.include(tickers, ticker)
            tickers.push(ticker)
            $(window).trigger('global:table:security:added', { ticker: ticker })

            update(ticker, 'add')
    
    remove_ticker = (ticker) ->
        if _.include(tickers, ticker)
            tickers = _.without(tickers, ticker)
            $(window).trigger('global:table:security:removed', { ticker: ticker })
            
            update(ticker, 'remove')


    add_cached_tickers = ->
        tickers = cache.get([cache_key, 'securities'].join(':')) ? []
    
    
    update = (ticker, message) ->
        cache.set([cache_key, 'securities'].join(':'), tickers)
        
        $(window).trigger 'table:tickers', { ticker: ticker, message: message }

        clearTimeout(refresh_timer)
        refresh_timer = _.delay(refresh, 100)
    
    
    # logic
    
    can_render = ->
        columns_filter.view().is(':hidden') and !sort_in_progress

    # render
    
    render = ->
        return unless deferred.state() == 'resolved'
        
        # prepare records
        records = (_.extend({}, securities_data[key], marketdata_data[key]) for key of securities_data)
        records = (records[key] = scope.utils.prepare_marketdata_record(record, columns_source.data) for key, record of records)
        
        # prepare columns
        columns = (columns_source.data[column] for column in columns_filter.columns())
        
        unless columns_sorter_is_active

            # render table head
            render_table_head_columns($('tr.columns', table_head_view), columns)
            render_table_head_columns_filter_cell($('tr.columns_filter', table_head_view), columns, columns_filter.view())
        
            # activate columns sort
        
            try
                $('tr.columns', table_head_view).sortable('destroy')
            catch error
                false
        
            $('tr.columns', table_head_view).sortable({
                containment:    $('tr.columns', table_head_view)
                tolerance:      'pointer'
                helper:         'clone'
                placeholder:    'ui-sortable-placeholder'
                appendTo:       table_head_view
            
                start:          (event, ui) ->
                    columns_sorter_is_active = true
                    ui.placeholder.addClass(ui.item.data('type')).html(ui.item.html())
                    active_sortable_index = $('tr.columns', table_head_view).children().not(ui.item).index(ui.placeholder)
            
                change:         (event, ui) ->
                    index = $('tr.columns', table_head_view).children().not(ui.item).index(ui.placeholder)
                
                    _.each(table_body_view.children(), (row) ->
                        row     = $(row)
                        cell    = $(row.children()[active_sortable_index])
                    
                        if active_sortable_index > index
                            cell.insertBefore(row.children()[index])
                        else
                            cell.insertAfter(row.children()[index])
                    )
                
                    active_sortable_index = index
            
                stop:           (event, ui) ->
                    columns_sorter_is_active = false
                    columns_filter.update_filtered_columns_order(_.map($('tr.columns', table_head_view).children(), (cell) -> $(cell).data('id')))
                
            })
        
        # render table body
        render_table_body_rows(table_body_view, records, columns)
        
        # post process
        colorize_table_body_cell_changes(table_body_view)
        colorize_rows(table_body_view)
        process_chart_tickers(table_body_view, chart_tickers)
        
        # toggle table visibility
        table_container_view.toggle(!_.isEmpty(records))
        
        # set access status flag
        table_container_view.removeClass('denied granted').addClass(access_marker)
        
        
        

    # view manipulation

    sort_records_by = (view) ->
        id                  = view.data('id')
        column              = _.find(prepared_columns, (column) -> column.id == id) ; return unless column?
        sort_field_column   = _.find(prepared_columns, (column) -> !!column.is_sort_field)
        
        if sort_field_column and sort_field_column == column
            column.is_sort_field *= -1
        else
            column.is_sort_field                = 1
            sort_field_column.is_sort_field     = 0
        
        cache.set([cache_key, 'sort_order'].join(':'), { column_id: column.id, direction: column.is_sort_field })
        
        render()
    
    
    toggle_columns_filter_visibility = ->
        columns_filter.view().toggle('blind', {}, 250)
    

    # data manupulation
    
    load = ->
        return if _.isEmpty(tickers)

        marketdata_source = mx.iss.marketdata2(engine.name, market.name, tickers.sort(), { only: 'marketdata' })
        
        $.when(marketdata_source).then ->
        
            access_marker = marketdata_source.data['x-marker']
            
            marketdata_data_version = _.first(marketdata_source.data.dataversion).version
        
            return refresh() unless marketdata_data_version == securities_data_version
            
            marketdata_data = _.reduce(marketdata_source.data.marketdata, ((memo, record) -> memo["#{record.BOARDID}:#{record.SECID}"] = record ; memo), {})
            
            render()
            
            reload()
        
        
    

    reload = ->
        clearTimeout(reload_timer)
        reload_timer = _.delay(load, 5000)
        

    # refresh - reload securities and marketdata
    
    refresh = ->

        securities_source = marketdata_source = if _.isEmpty(tickers) then {} else mx.iss.marketdata2(engine.name, market.name, tickers.sort())
        
        $.when(securities_source, marketdata_source).then ->

            unless _.isEmpty(securities_source) and _.isEmpty(marketdata_source)

                access_marker = marketdata_source.data['x-marker']
                
                securities_data_version = marketdata_data_version = _.first(securities_source.data.dataversion).version

                securities_data = _.reduce(securities_source.data.securities, ((memo, record) -> memo["#{record.BOARDID}:#{record.SECID}"] = record ; memo), {})
                marketdata_data = _.reduce(marketdata_source.data.marketdata, ((memo, record) -> memo["#{record.BOARDID}:#{record.SECID}"] = record ; memo), {})
            
            else
                
                securities_data = []
                marketdata_data = []
            
            render()
            
            reload()
        
    #
    
    add_cached_tickers()
    
    $(window).on 'chart:instruments:changed', (event, instruments, message) ->
        chart_tickers = _.map(instruments, (ticker) -> [ticker.board, ticker.id].join(':'))
        render()
        
    #

    ready_for_render.then ->

        refresh()
        
        $(window).on 'security:selected', (event, data) ->
            return unless data.engine == engine.name and data.market == market.name
            add_ticker([data.board, data.param].join(':'))
            
        
        $(window).on 'table:filtered_columns:updated', (event, data) ->
            return unless data.engine == engine.name and data.market == market.name
            render()

        table_container_view.on 'click', 'div.columns_filter_trigger', toggle_columns_filter_visibility
        
        # ticker information
        
        table_container_view.on 'click', 'tr.ticker', (event) ->
            toggle_ticker_information($(@))
        
        # tickers manipulation
        
        $(window).on "global:table:security:add:#{engine.name}:#{market.name}", (event, memo) ->
            add_ticker(memo.ticker)
        
        $(window).on "global:table:security:remove:#{engine.name}:#{market.name}", (event, memo) ->
            remove_ticker(memo.ticker)
        
        # chart manipulations
        
        deferred.resolve()
    
    deferred.promise
        tickers: -> tickers
    
    
    
$.extend scope,
    table: widget
