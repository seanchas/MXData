root    = @
scope   = root['mx']['data']


$       = jQuery


default_filter_name = 'preview'
full_filter_name    = 'full'


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



filter_columns = (columns, filters) ->
    data = []

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
            .toggleClass('sortable', column.is_ordered == 1)
            .html("<span>#{column.short_title}</span>")
    
    row.append $("<td>")
        .addClass("remove")
        .html("")

    row


render_body_row = (record, columns) ->
    row = $("<tr>")
        .addClass("row")
        .attr("data-param", "#{record.BOARDID}:#{record.SECID}")
    
    for column in columns when column._is_visible
        row.append $("<td>")
            .addClass(column.type)
            .html(record[column.name] ? '&mdash;')
    
    row.append $("<td>")
        .addClass("remove")
        .html("<span>&ndash;</span>")
    
    row



widget = (wrapper, market_object) ->
    wrapper     = $(wrapper); return if _.size(wrapper) == 0
    
    
    
    engine      = market_object.trade_engine_name
    market      = market_object.market_name
    

    container   = make_container(wrapper, market_object)
    table       = $("table", container)
    table_body  = $("tbody", table)
    table_head  = $("thead", table)
    

    fds = undefined
    cds = undefined
    rds = undefined
            
    init_data_sources = _.once ->
        fds = mx.iss.marketdata_filters engine, market
        cds = mx.iss.marketdata_columns engine, market
    

    securities          = []
    filtered_columns    = undefined
    
    reload_timeout      = undefined
    
    should_render_head  = true
    
    sort                = {}

    #
    # utils
    #
    
    securityExists = (data) ->
        _.size(security for security in securities when security == "#{data.board}:#{data.param}") > 0

    addSecurity = (data) ->
        securities.push "#{data.board}:#{data.param}"
        
        clearTimeout reload_timeout
        reload_timeout = _.delay reload, 300
    
    removeSecurity = (param) ->
        securities = _.without securities, param
        render()
    
    #
    # reload
    #
    
    reload = ->
        rds = mx.iss.marketdata(engine, market, securities)
        rds.then render
        #refresh()
    
    #
    # render
    #
    
    render = ->
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
            
            filtered_columns ?= filter_columns(columns, filters)
            
            table_head.empty()
            
            table_head.append render_head_row filtered_columns
            
    
    render_body = ->
        init_data_sources()
        
        $.when(
            fds,
            cds,
            rds
        ).then (filters, columns, data) ->

            filtered_columns ?= filter_columns(columns, filters)
            
            if sort.column? and sort.direction?
                direction   = if sort.direction == 'asc' then 1 else -1
                data        = data.sort (a, b) -> direction * if a[sort.column] > b[sort.column] then 1 else if a[sort.column] < b[sort.column] then -1 else 0
                    
            table_body.empty()

            for record in data when _.include securities, "#{record.BOARDID}:#{record.SECID}"
                table_body.append render_body_row record, filtered_columns
            
    

    render_filter = (row) ->
        row = $(row); return if _.size(row) == 0
        
        $.when(
            fds,
            cds,
            rds
        ).then (filters, columns, data) ->
            
            [board, param] = row.data("param").split(":")
            return unless param? and board?
        
            filtered_columns ?= filter_columns(columns, filters)
            
            record = _.first(record for record in data when record.SECID == param and record.BOARDID == board)
            return unless record?
            
            filter_row  = $("<tr>")
                .attr("data-param", "#{board}:#{param}")
                .addClass("filter")

            filter_cell = $("<td>")
                .attr("colspan", _.size($("td", row)))
            
            list = $("<ul>")
            
            for column in filtered_columns
                list.append $("<li>")
                    .attr('data-name', column.name)
                    .toggleClass("visible", column._is_visible)
                    .html("<span title=\"#{column.title}\">#{column.short_title}</span>: <span>#{record[column.name] ? '&mdash;'}</span>")
                
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
        _.delay reload, 60 * 1000
    
    
    #
    # event observers
    #

    onSecuritySelected = (event, data) ->
        return unless data.engine == engine and data.market == market
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
        
        render_body()
    

    onRowClick = (event) ->
        row = $(event.currentTarget)
        $("tr.filter", table).not("[data-param=#{row.data('param')}]").remove()
        filter_row = row.next("tr.filter")
        if _.size(filter_row) > 0
            filter_row.remove()
        else
            render_filter row
    
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
    
    table.on "click", "tbody tr.row td.remove", onRemoveCellClick
    
    


$.extend scope,
    table: widget
