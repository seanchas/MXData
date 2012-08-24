root    = @
scope   = root['mx']['data']

$       = jQuery

cache   = kizzy('data.table')


default_filter  = 'preview'


maximum_active_columns = 10


prepare_columns = (filters, columns, options = {}) ->
    
    filters                 = filters[default_filter]
    valid_columns           = _.reject columns, (column) -> !!column.is_system
    
    visible_columns_ids     = _.pluck(filters, 'id')
    hidden_columns_ids      = _.difference(_.pluck(valid_columns, 'id'), visible_columns_ids)
    
    data = []

    for id in visible_columns_ids
        continue if !!columns[id].is_system
        data.push(_.tap(columns[id], (column) -> column.is_hidden = 0))
    
    for id in hidden_columns_ids
        continue if !!columns[id].is_system
        data.push(_.tap(columns[id], (column) -> column.is_hidden = 1))
    
    if options.cached_sort?
        column = columns[options.cached_sort.column_id]
        column.is_sort_field = options.cached_sort.direction if column?
    
    unless _.find(data, (column) -> !!column.is_sort_field)
        _.find(data, (column) -> !!column.is_ordered)?.is_sort_field = 1
    
    data


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
    
    container.appendTo(wrapper).hide()



make_table_header_columns_view = (columns, options = {}) ->
    row_view = $('<tr>')
        .addClass('columns')
    
    for column in columns
        cell_view = $('<td>')
            .data({ id: column.id, type: column.type })
            .attr('title', column.title)
            .addClass(column.type)
            .toggleClass('sortable', !!column.is_ordered)
        
        if options.sort_column == column
            cell_view
                .addClass('sort_field')
                .toggleClass('asc', column.is_sort_field > 0)
                .toggleClass('desc', column.is_sort_field < 0)
        
        cell_content_view = $('<span>')
            .html(column.short_title)
        
        cell_content_view.appendTo(cell_view)
        cell_view.appendTo(row_view)

    row_view



make_table_header_columns_filter_container_view = (columns, options = {}) ->
    row_view = $('<tr>')
        .addClass('columns_filter_container')
    
    row_view.append(
        $('<td>')
            .attr('colspan', columns.length)
    )
    
    row_view



render_table_head = (container, columns, options = {}) ->
    container.empty()
    
    container.append(make_table_header_columns_view(columns, options))

    container.append(make_table_header_columns_filter_container_view(columns, options))
    
    container
    


render_table_body = (container, columns, records, options = {}) ->
    prev_rows = $('tr', container).detach()
    
    container.empty()
    
    if options.sort_column?
        records = _.sortBy(records, (column) -> column[options.sort_column.name])
        records = records.reverse() if options.sort_column.is_sort_field < 0
    
    for record, index in records
        
        row_view = $('<tr>')
            .data({ 'board': record.BOARDID, 'id': record.SECID, 'record': record })
            .addClass('record anchor')
            .toggleClass('even', (index + 1) % 2 == 0)
            .toggleClass('odd', (index + 1) % 2 == 1)
        
        
        for column in columns
            
            value               = record[column.name]
            value_for_render    = scope.utils.render_marketdata_record_value(column.name, record, column)
            
            cell_view = $('<td>')
                .data('name', column.name)
                .addClass(column.type)
                .toggleClass('link', !!column.is_linked)
                .append($('<span>').html(value_for_render ? '&mdash;'))
            
            # trends
            trend = record.trends[column.name]
            if trend?
                cell_view.toggleClass('up',   trend.value > 0)
                cell_view.toggleClass('down', trend.value < 0)
                cell_view.toggleClass('trend_by_self', trend.self)
                cell_view.toggleClass('trend_by_other', !trend.self)
                
                unless trend.self
                    cell_view.data('value', value)
                    cell_view.data('value_for_render', value_for_render)
                
            cell_view.appendTo(row_view)
        
        row_view.appendTo(container)
        
        
    for row in container.children()
        row         = $(row)
        prev_row    = $(_.find(prev_rows, (prev_row) -> prev_row = $(prev_row) ; prev_row.data('board') == row.data('board') and prev_row.data('id') == row.data('id')))
        
        for cell in row.children('.trend_by_other')
            cell        = $(cell)
            prev_cell   = $(_.find(prev_row.children(), (prev_cell) -> prev_cell = $(prev_cell) ; prev_cell.data('name') == cell.data('name')))

            value       = cell.data('value')
            prev_value  = prev_cell.data('value')
            
            continue unless value? and prev_value?
            
            sign        = if value > prev_value then 'up' else if value < prev_value then 'down' else undefined
            
            value       = cell.data('value_for_render')
            prev_value  = prev_cell.data('value_for_render')
            
            if value? and prev_value?

                before  = ''
                after   = ''
            
                if value.length == prev_value.length
                    
                    index = 0
                    for i in [0..value.length - 1]
                        break if value[i] != prev_value[i]
                        index++
                    
                    before  = value.slice(0, index)
                    after   = value.slice(index)
                    
                else
                    after = value
            
                html = $('<span>').html(before)
                html.append($('<em>').addClass(sign).html(after))
                
                cell.html(html)
            
        
    prev_rows.remove()
        

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
    records_source          = undefined

    ready_for_render        = $.when columns_source, filters_source, columns_filter
    
    tickers                 = []
    
    
    sort_in_progress        = false
    active_sortable_index   = 0
    
    prepared_columns        = undefined
    
    reload_timer            = undefined
    
    # tickers
    
    add_ticker = (ticker) ->
        tickers.push(ticker) unless _.include(tickers, ticker)
        update()
    
    remove_ticker = ->

    add_cached_tickers = ->
        tickers = cache.get([cache_key, 'securities'].join(':')) ? []
    
    
    update = ->
        cache.set([cache_key, 'securities'].join(':'), tickers)
        reload()
    
    
    # logic
    
    can_render = ->
        columns_filter.view().is(':hidden') and !sort_in_progress

    # render
    
    render = (force = false) ->
        return unless can_render()
        
        columns_filter.view().detach()
        
        $('tr', table_head_view).sortable('destroy')

        prepared_columns ?= prepare_columns(filters_source.data, columns_source.data, { cached_sort: cache.get([cache_key, 'sort_order'].join(':')) })

        active_columns = _.filter(prepared_columns, (column) -> _.include(columns_filter.columns(), column.id))
        
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
    
    
    toggle_columns_filter_visibility = ->
        columns_filter.view().toggle('blind', {}, 250)
    

    # data manupulation
    
    reload = ->
        return if _.isEmpty(tickers)
        
        records_source = mx.iss.marketdata(engine, market, tickers.sort())

        records_source.then render
        
        clearTimeout(reload_timer) ; reload_timer = _.delay(reload, 5000)
        
        

    # ready for render

    ready_for_render.then ->

        add_cached_tickers()
        
        reload()
        
        table_head_view.on 'click', 'td.sortable',          -> sort_records_by $(@)

        $(window).on 'security:selected', (event, data) ->
            return unless data.engine == engine and data.market == market
            add_ticker([data.board, data.param].join(':'))
            
        
        $(window).on 'table:filtered_columns:updated', (event, data) ->
            return unless data.engine == engine and data.market == market
            render(true)

        table_container_view.on 'click', 'div.columns_filter_trigger', toggle_columns_filter_visibility
        
        
        deferred.resolve()
    

    deferred.promise
        tickers: -> tickers
    
    
    
$.extend scope,
    table: widget
