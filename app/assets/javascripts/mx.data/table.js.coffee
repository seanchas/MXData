root    = @
scope   = root['mx']['data']

$       = jQuery

cache   = kizzy('data.table')


default_filter  = 'preview'


# main container

make_table_container_view = (wrapper, descriptor) ->
    container = $('<div>')
        .data({ engine: descriptor.trade_engine_name, market: descriptor.market_name })
        .addClass('table_container')
    
    title = $('<h4>')
        .addClass('title')
        .html("#{descriptor.trade_engine_title} :: #{descriptor.market_title}")
        .appendTo(container)
    
    columns_filter_trigger = $('<div>')
        .addClass('columns_filter_trigger')
        .append($('<span>').html('Поля'))
        .appendTo(title)
    
    container.append($('<div>').addClass('columns_filter_wrapper').hide())
    
    container.append $('<table>')
        .addClass('records')
        .html('<thead></thead><tbody></tbody>')
    
    table_head_view = $('thead', container)
    
    table_head_view.append($('<tr>').addClass('columns'))
    table_head_view.append($('<tr>').addClass('columns_filter'))
    
    container.appendTo(wrapper).hide()


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
    cell = $('<td>')
        .data({ id: column.id, type: column.type })
        .attr('title', column.title)
        .addClass(column.type)
        .toggleClass('sortable', !!column.is_ordered)
        .append($('<span>').html(column.short_title))
    
    cell


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
    rows = container.children()
    
    for record in records
        
        record.ticker = [record.BOARDID, record.SECID].join(':')
        
        row = _.first(row for row in rows when $(row).data('id') == record.ticker)
        
        unless row?
            row = render_table_body_row(record, columns, options)
            container.append(row)
        
        row = $(row)
        
        render_table_body_row_cells(row, record, columns, options)
    

    tickers = _.pluck(records, 'ticker')
    

    for row in rows
        row = $(row)
        row.remove() unless _.include(tickers, row.data('id'))
    
    container
            

render_table_body_row = (record, columns, options = {}) ->
    row = $('<tr>')
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
       

widget = (wrapper, descriptor) ->
    wrapper = $(wrapper) ; return if _.isEmpty(wrapper)
    
    deferred    = new $.Deferred
    
    engine      = descriptor.trade_engine_name
    market      = descriptor.market_name
    cache_key   = [engine, market].join(':')
    
    table_container_view    = make_table_container_view(wrapper, descriptor)
    table_view              = $('table', table_container_view)
    table_head_view         = $('thead', table_view)
    table_body_view         = $('tbody', table_view)
    columns_filter_view     = $('div.columns_filter_wrapper', table_container_view)
    
    
    columns_filter          = scope.table_columns_filter(columns_filter_view, engine, market)


    filters_source          = mx.iss.marketdata_filters(engine, market)
    columns_source          = mx.iss.marketdata_columns(engine, market)

    securities_source       = undefined
    marketdata_source       = undefined

    records_source          = undefined

    ready_for_render        = $.when columns_source, filters_source, columns_filter
    
    tickers                 = []
    
    
    sort_in_progress        = false
    active_sortable_index   = 0
    
    prepared_columns        = undefined
    
    reload_timer            = undefined
    
    securities_data_version = 0
    marketdata_data_version = 0
    
    securities_data         = undefined
    marketdata_data         = undefined
    
    
    # tickers
    
    add_ticker = (ticker) ->
        unless _.include(tickers, ticker)
            tickers.push(ticker)
            $(window).trigger('global:table:security:added', { ticker: ticker })

        update()
    
    remove_ticker = (ticker) ->
        if _.include(tickers, ticker)
            tickers = _.without(tickers, ticker)
            $(window).trigger('global:table:security:removed', { ticker: ticker })
            
        update()


    add_cached_tickers = ->
        tickers = cache.get([cache_key, 'securities'].join(':')) ? []
    
    
    update = ->
        cache.set([cache_key, 'securities'].join(':'), tickers)
        refresh()
    
    
    # logic
    
    can_render = ->
        columns_filter.view().is(':hidden') and !sort_in_progress

    # render
    
    render1 = (force = false) ->
        unless force
            return unless can_render()
        
        columns_filter.view().detach()
        
        $('tr', table_head_view).sortable('destroy')

        prepared_columns ?= prepare_columns(filters_source.data, columns_source.data, { cached_sort: cache.get([cache_key, 'sort_order'].join(':')) })

        active_columns = _.filter(prepared_columns, (column) -> _.include(columns_filter.columns(), column.id))
        
        active_columns = _.sortBy(active_columns, (column) -> _.indexOf(columns_filter.columns(), column.id) )
        
        sort_column = _.find(prepared_columns, (column) -> !!column.is_sort_field)
        
        records     = _.map(records_source.data, (record) -> scope.utils.prepare_marketdata_record(record, columns_source.data))


        render_table_head(table_head_view, active_columns, { sort_column: sort_column })

        render_table_body(table_body_view, active_columns, records, { sort_column: sort_column, columns: columns_source.data })


        table_container_view.toggle(!_.isEmpty(records_source.data))


        $('tr.columns_filter_container td', table_head_view).html(columns_filter.view()) if table_container_view.is(':visible')

        $('tr.columns', table_head_view).sortable({
            
            containment:    $('tr.columns', table_head_view)
            opacity:        .75
            placeholder:    'ui-sortable-placeholder'
            tolerance:      'pointer'
            
            helper: (event, element) ->
                table = $('<table>').addClass('records').html('<thead><tr></tr></thead>').appendTo(table_container_view)
                $('thead tr', table).append(element.clone())
                table
            
            start: (event, ui) ->
                sort_in_progress = true
                ui.placeholder.addClass(ui.item.data('type')).html(ui.item.html())
                active_sortable_index = $('tr td', table_head_view).index(ui.item)
            
            change: (event, ui) ->
                current_index = $('tr td', table_head_view).not(ui.item).index(ui.placeholder)
                
                _.each(table_body_view.children(), (row) ->
                    row     = $(row)
                    cell    = $(row.children()[active_sortable_index])
                    
                    if active_sortable_index > current_index
                        cell.insertBefore(row.children()[current_index])
                    else
                        cell.insertAfter(row.children()[current_index])
                )
                
                active_sortable_index = current_index
            
            stop: ->
                sort_in_progress = false
                columns_filter.update_filtered_columns_order(_.map($('tr.columns td', table_head_view), (cell) -> $(cell).data('id')))

        })
    
    
    render = ->
        
        # prepare records
        records = (_.extend({}, securities_data[key], marketdata_data[key]) for key of securities_data)
        records = (records[key] = scope.utils.prepare_marketdata_record(record, columns_source.data) for key, record of records)
        
        # prepare columns
        columns = (columns_source.data[column] for column in columns_filter.columns())

        # render table head
        render_table_head_columns($('tr.columns', table_head_view), columns)
        render_table_head_columns_filter_cell($('tr.columns_filter', table_head_view), columns, columns_filter.view())
        
        
        # render table body
        render_table_body_rows(table_body_view, records, columns)
        
        # post process
        colorize_table_body_cell_changes(table_body_view)
        
        # toggle table visibility
        table_container_view.toggle(!_.isEmpty(records))
        
            # activate columns sort
        $('tr.columns', table_head_view).sortable({
            containment:    $('tr.columns', table_head_view)
            tolerance:      'pointer'
            helper:         'clone'
            placeholder:    'ui-sortable-placeholder'
            appendTo:       table_head_view
            
            start:          (event, ui) ->
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
                columns_filter.update_filtered_columns_order(_.map($('tr.columns', table_head_view).children(), (cell) -> $(cell).data('id')))
                
        })
        
        

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
    
    
    append_external_views = ->
        
    
    
    toggle_columns_filter_visibility = ->
        columns_filter.view().toggle('blind', {}, 250)
    

    # data manupulation
    
    load = ->
        return if _.isEmpty(tickers)

        marketdata_source = mx.iss.marketdata2(engine, market, tickers.sort(), { only: 'marketdata' })
        
        $.when(marketdata_source).then ->
        
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
        console.log "initial loading: #{engine}/#{market} at #{new Date}"
        
        securities_source = marketdata_source = if _.isEmpty(tickers) then {} else mx.iss.marketdata2(engine, market, tickers.sort())
        
        $.when(securities_source, marketdata_source).then ->

            unless _.isEmpty(securities_source) and _.isEmpty(marketdata_source)

                securities_data_version = marketdata_data_version = _.first(securities_source.data.dataversion).version

                securities_data = _.reduce(securities_source.data.securities, ((memo, record) -> memo["#{record.BOARDID}:#{record.SECID}"] = record ; memo), {})
                marketdata_data = _.reduce(marketdata_source.data.marketdata, ((memo, record) -> memo["#{record.BOARDID}:#{record.SECID}"] = record ; memo), {})
            
            else
                
                securities_data = []
                marketdata_data = []
            
            render()
            
            reload()
        
    

    # ready for render

    ready_for_render.then ->

        append_external_views()

        add_cached_tickers()
        
        refresh()
        
        #table_head_view.on 'click', 'td.sortable',          -> sort_records_by $(@)
        
        $(window).on 'security:selected', (event, data) ->
            return unless data.engine == engine and data.market == market
            add_ticker([data.board, data.param].join(':'))
            
        
        $(window).on 'table:filtered_columns:updated', (event, data) ->
            return unless data.engine == engine and data.market == market
            render()

        table_container_view.on 'click', 'div.columns_filter_trigger', toggle_columns_filter_visibility
        
        
        $(window).on "global:table:security:add:#{engine}:#{market}", (event, memo) ->
            add_ticker(memo.ticker)
        
        $(window).on "global:table:security:remove:#{engine}:#{market}", (event, memo) ->
            remove_ticker(memo.ticker)
        
        deferred.resolve()
    

    deferred.promise
        tickers: -> tickers
    
    
    
$.extend scope,
    table: widget
