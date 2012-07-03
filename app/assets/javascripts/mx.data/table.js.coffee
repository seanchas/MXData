root    = @
scope   = root['mx']['data']


$       = jQuery


cache                       = kizzy('data.table')



default_filter_name = 'preview'
full_filter_name    = 'full'


escape_selector = (string) ->
    string.replace /([\W])/g, "\\$1"


make_container = (wrapper, market) ->
    container = $("<div>")
        .attr
            "id": "#{market.trade_engine_name}-#{market.market_name}-container"

    title = $("<h4>")
        .html("#{market.trade_engine_title} :: #{market.market_title}")
    
    table = $("<table>")
        .attr
            "id": "#{market.trade_engine_name}-#{market.market_name}-table"
        .html("<thead></thead><tbody></tbody>")
    
    container.append title
    container.append table
    
    container.appendTo wrapper
    container.hide()



filter_columns = (columns, filters, cache = undefined) ->
    data = []
    
    if cache?
        
        for column_meta in cache
            column = columns[column_meta[0]]
            if column?
                column._is_visible = !!column_meta[1]
                data.push(column)
        
            delete columns[column_meta[0]]
        
        for id, column of columns
            data.push column if column.is_system == 0
        
    else
        visible_columns = (column_descriptor.id for column_descriptor in filters[default_filter_name])
        for id in visible_columns
            data.push(_.tap columns[id], (column) -> column._is_visible = true) if columns[id].is_system == 0
    
        hidden_columns = (column_descriptor.id for column_descriptor in filters[full_filter_name] when not _.include visible_columns, column_descriptor.id)
        for id in hidden_columns
            data.push(_.tap columns[id], (column) -> column._is_visible = false) if columns[id].is_system == 0

    data


render_head_row = (columns) ->
    row = $("<tr>")
    
    for column in columns when column._is_visible
        row.append $("<td>")
            .attr(
                "data-column":  column.name
                "title":        column.title
            )
            .addClass(column.type)
            .toggleClass('sortable', column.is_ordered == 1)
            .html("<span>#{column.short_title}</span>")
    
    row.append $("<td>")
        .addClass("chart")
        .html("")

    #row.append $("<td>")
    #    .addClass("remove")
    #    .html("")

    row


render_body_row = (record, columns, index) ->
    row = $("<tr>")
        .addClass("row")
        .toggleClass("even",    index % 2 == 0)
        .toggleClass("odd",     index % 2 == 1)
        .attr("data-param", "#{record.BOARDID}:#{record.SECID}")
    
    for column in columns when column._is_visible
        row.append $("<td>")
            .addClass(column.type)
            .toggleClass('link', column.is_linked == 1)
            .html($('<span>').html(record[column.name] ? '&mdash;'))
    
    row.append $("<td>")
        .attr('data-title', record['SHORTNAME'])
        .addClass("chart")
        .html("<div></div>")
    
    #row.append $("<td>")
    #    .addClass("remove")
    #    .html("<span>&ndash;</span>")
    
    row


check_filtered_columns_cache = (cache) ->
    return false unless _.isArray(cache)
    
    result = true
    
    for entry in cache
        result = false if !_.isArray(entry) or _.size(entry) != 2

    return result


widget = (wrapper, market_object) ->
    wrapper     = $(wrapper); return if _.size(wrapper) == 0
    
    engine      = market_object.trade_engine_name
    market      = market_object.market_name
    
    cache_key   = "#{engine}:#{market}"
    
    container   = make_container(wrapper, market_object)
    table       = $("table", container)
    table_body  = $("tbody", table)
    table_head  = $("thead", table)
    

    fds = undefined
    cds = undefined
    rds = undefined
    
    stale = null
            
    init_data_sources = _.once ->
        fds = mx.iss.marketdata_filters engine, market
        cds = mx.iss.marketdata_columns engine, market
    

    securities          = []
    securities_cached   = false
    filtered_columns    = undefined
    
    reload_timeout      = undefined
    
    should_render_head  = true
    
    render_is_locked    = false
    
    sort                = {}
    
    cached_filtered_columns = undefined

    #
    # utils
    #
    
    securityExists = (data) ->
        _.size(security for security in securities when security == "#{data.board}:#{data.param}") > 0

    addSecurity = (data) ->
        securities.push "#{data.board}:#{data.param}"
        cache.set("#{cache_key}:securities", securities)
        clearTimeout reload_timeout
        reload_timeout = _.delay reload, 300
    
    removeSecurity = (param) ->
        securities = _.without securities, param
        cache.set("#{cache_key}:securities", securities)
        render()
    
    #
    # reload
    #
    
    reload = ->
        rds = mx.iss.marketdata(engine, market, securities)
        rds.then render
        refresh()
    
    #
    # render
    #
    
    render = ->
        return if render_is_locked

        render_head()
        render_body()
        
        container.hide() if _.size(securities) == 0
        container.show() if _.size(securities) > 0
    
    render_head = ->
        return unless should_render_head
        
        should_render_head = false
        
        init_data_sources()
        
        $.when(
            fds,
            cds
        ).then (filters, columns) ->
            
            filtered_columns ?= filter_columns(columns, filters, cached_filtered_columns)
            
            table_head.empty()
            
            table_head.append render_head_row filtered_columns
            
    
    render_body = ->
        init_data_sources()
        
        $.when(
            fds,
            cds,
            rds
        ).then (filters, columns, data) ->

            (delete stale ; stale = null) if stale?

            filtered_columns ?= filter_columns(columns, filters, cached_filtered_columns)
            
            if sort.column? and sort.direction?
                direction   = if sort.direction == 'asc' then 1 else -1
                data        = data.sort (a, b) -> direction * if a[sort.column] > b[sort.column] then 1 else if a[sort.column] < b[sort.column] then -1 else 0
                    
            table_body.empty()

            for record, index in data when _.include securities, "#{record.BOARDID}:#{record.SECID}"
                table_body.append render_body_row record, filtered_columns, index + 1
            
            render_chart_instruments()
        
            stale = data
    
    
    render_chart_instruments = (instruments) ->
        instruments ?= scope.caches.chart_instruments()
        for row in $("tr", table_body)
            row = $(row)
            index = _.first(index for instrument, index in instruments when row.data('param') == "#{instrument.board}:#{instrument.id}")
            $('td.chart div', row).css('background-color', (if index? then scope.colors[index] else '')).toggleClass('active', index?)
            
    

    render_filter = (row) ->
        row = $(row); return if _.size(row) == 0
        
        $.when(
            fds,
            cds,
            rds
        ).then (filters, columns, data) ->
            
            [board, param] = row.data("param").split(":")
            return unless param? and board?
        
            filtered_columns ?= filter_columns(columns, filters, cached_filtered_columns)
            
            record = _.first(record for record in data when record.SECID == param and record.BOARDID == board)
            return unless record?
            
            filter_row  = $("<tr>")
                .attr("data-param", "#{board}:#{param}")
                .toggleClass('odd', row.hasClass('odd'))
                .addClass("filter")

            filter_cell = $("<td>")
                .attr("colspan", _.size($("td", row)))
            
            list = $("<ul>")
            
            for column in filtered_columns
                list.append $("<li>")
                    .attr('data-name', column.name)
                    .toggleClass("visible", column._is_visible)
                    .html("<span title=\"#{column.title}\">#{column.short_title}</span>: <span class=\"value\">#{record[column.name] ? '&mdash;'}</span>")
                
            button = $("<button>").html("Готово")
            
            filter_cell.append list
            filter_cell.append button
            filter_row.append filter_cell
            row.after filter_row
            
            $(list).sortable();
            
    
    #
    # refresh
    #
    
    refresh = ->
        _.delay reload, 5 * 1000
    
    
    #
    # event observers
    #

    onSecuritySelected = (event, data) ->
        return unless data.engine == engine and data.market == market
        unless data.no_cache == true and securities_cached == true
            addSecurity data unless securityExists data
    
    onSortableCellClick = (event) ->
        cell        = $(event.currentTarget)
        column      = cell.data('column')
        direction   = if cell.hasClass('asc') then 'desc' else 'asc'
        
        $("td.sortable", table_head).removeClass("asc").removeClass("desc")
        
        cell.toggleClass 'asc',     direction == 'asc'
        cell.toggleClass 'desc',    direction == 'desc'
        
        sort        =
            column:     column
            direction:  direction
        
        cache.set("#{cache_key}:sort", sort)

        render_body()
    

    onRowClick = (event) ->
        render_is_locked = true
        row = $(event.currentTarget)
        $("tr.filter", table).not("[data-param=#{row.data('param')}]").remove()
        filter_row = row.next("tr.filter")
        if _.size(filter_row) > 0
            filter_row.remove()
            render_is_locked = false
        else
            render_filter row
    
    onChartCellClick = (event) ->
        event.stopPropagation()
        cell =  $(event.currentTarget)
        [board, param] = cell.closest('tr').data('param').split(':');
        $(window).trigger('security:to:chart', { engine: engine, market: market, board: board, id: param, title: cell.data('title') });
    
    onRemoveCellClick = (event) ->
        event.stopPropagation()
        removeSecurity $(event.currentTarget).parent('tr').data('param')
    
    onFilterColumnClick = (event) ->
        $(event.currentTarget).toggleClass('visible')
    

    onFilterButtonClick = (event) ->
        cell            = $(event.currentTarget).parent('td')
        
        sorted_columns  = []
        visible_columns = []
        
        _.each $('li', cell), (item) -> item = $(item); sorted_columns.push item.data('name'); visible_columns.push item.data('name') if item.hasClass('visible');
        
        $.when(
            fds,
            cds
        ).then (filters, columns) ->
            
            filtered_columns ?= filter_columns(columns, filters)
            
            filtered_columns = _.sortBy filtered_columns, (column) ->
                column._is_visible = _.include visible_columns, column.name
                _.indexOf sorted_columns  , column.name
            
            cached_filtered_columns = ([column.id, column._is_visible] for column in filtered_columns)
            
            cache.set("#{cache_key}:filtered_columns", cached_filtered_columns)
        
        render_is_locked = false
        should_render_head = true
        render(true)
        
        
    
    #
    # event listeners
    #
    
    $(window).on "security:selected", onSecuritySelected
    
    table.on "click", "thead td.sortable", onSortableCellClick
    
    table.on "click", "tbody tr.row", onRowClick

    table.on "click", "tbody tr.filter li", onFilterColumnClick
    
    table.on "click", "tbody tr.filter button", onFilterButtonClick
    
    table.on "click", "tbody tr.row td.chart", onChartCellClick

    table.on "click", "tbody tr.row td.remove", onRemoveCellClick
    
    $(window).on "chart:instruments:changed", (event, instruments, message) ->
        render_chart_instruments instruments
    
    #
    
    cached_securities = cache.get("#{cache_key}:securities")
    securities_cached = !!cached_securities
    
    if securities_cached
        for security in cached_securities
            [board, param] = security.split(':') ; security = { board: board, param: param }
            addSecurity security unless securityExists security
    
    cached_filtered_columns = cache.get("#{cache_key}:filtered_columns")
    cached_filtered_columns = undefined unless check_filtered_columns_cache cached_filtered_columns
    
    sort = cache.get("#{cache_key}:sort") ? {}
    
    return
    
    


$.extend scope,
    table: widget
