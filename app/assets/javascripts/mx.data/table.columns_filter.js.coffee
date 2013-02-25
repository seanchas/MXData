root    = @
scope   = root['mx']['data']

$       = jQuery

default_filter_name = 'preview'


max_active_columns  = 10
min_active_columns  = 3


filter_columns = (columns, filters, cached_filtered_columns) ->
    return cached_filtered_columns if cached_filtered_columns and _.isArray(cached_filtered_columns)
    column.id for column in filters[default_filter_name] when columns[column.id]? and !columns[column.id].is_system


make_filtered_columns_container_view = (wrapper, columns, filtered_columns) ->
    
    table_view = $('<table>')
        .html('<thead></thead><tbody></tbody>')
        .appendTo(wrapper)
    
    table_body_view = $('tbody', table_view)
    
    row_view = $('<tr>')
        .appendTo(table_body_view)
    
    append_filtered_column(table_view, columns[id]) for id in filtered_columns when id?
    
    table_view
    

append_filtered_column = (wrapper, column) ->
    container = $('tbody tr', wrapper)
    cell_view = $('<td>')
        .data('id', column.id)
        .html(column.short_title)
        .appendTo(container)


remove_filtered_column = (wrapper, id) ->
    siblings    = $('tbody tr td', wrapper)
    cell_view   = $(_.first(cell_view for cell_view in siblings when $(cell_view).data('id') == id)) ; return if cell_view.length == 0
    cell_view.remove()


make_source_columns_view = (columns, filtered_columns) ->
    
    list_view = $('<ul>')
        .addClass('source_list clearfix')
    
    for column in columns when !column.is_system
        
        id = parseInt(column.id)
        
        item_view = $('<li>')
            .addClass('item')
            .data('id', id)
            .toggleClass('active', _.include(filtered_columns, id))
            .appendTo(list_view)
        
        input_view = $('<input>')
            .attr('type', 'checkbox')
            .val(id)
        
        label_view = $('<label>')
            .html(column.short_title)
        
        hint_view = $('<em>')
            .html(column.title)
        
        $('<div>')
            .append(label_view.prepend(input_view))
            .append(hint_view)
            .appendTo(item_view)
        
    $('input', list_view).val(filtered_columns)
    
    list_view.hide()


toggle_source_column_state = (wrapper, id, is_checked) ->
    item = $(_.first(item for item in $('li', wrapper) when $(item).data('id') == id)) ; return if item.length == 0
    item.toggleClass('active', is_checked)
    

disable_inactive_source_columns = (wrapper) ->
    wrapper = $(wrapper) ; return if wrapper.length == 0
    wrapper.addClass('disabled')
    $('input:not(:checked)', wrapper).prop('disabled', true)


enable_inactive_source_columns = (wrapper) ->
    wrapper = $(wrapper) ; return if wrapper.length == 0
    wrapper.removeClass('disabled')
    $('input:not(:checked)', wrapper).prop('disabled', false)


disable_active_source_columns = (wrapper) ->
    wrapper = $(wrapper) ; return if wrapper.length == 0
    $('input:checked', wrapper).prop('disabled', true)


enable_active_source_columns = (wrapper) ->
    wrapper = $(wrapper) ; return if wrapper.length == 0
    $('input:checked', wrapper).prop('disabled', false)



widget = (wrapper, engine, market) ->
    wrapper = $(wrapper) ; return if wrapper.length == 0
	
    deferred = new $.Deferred
    
    cache_key = [engine, market].join(':')
    
    filtered_columns_container_view     = undefined
    source_columns_container_view       = undefined
    
    columns_data_source = mx.iss.security_marketdata_columns(engine, market);
    filters_data_source = mx.iss.marketdata_filters(engine, market);
    
    
    ready               = $.when(columns_data_source, filters_data_source)
    
    filtered_columns    = undefined
    
    source_columns_view = undefined
    

    columns = (id) -> if id? then columns_data_source.result.data.hash('id')[id] else columns_data_source.result.data.hash('id')
    
    filters = -> filters_data_source.data
    
    
    update = ->
        scope.caches.table_filtered_columns(cache_key, filtered_columns)
        $(window).trigger('table:filtered_columns:updated', { engine: engine, market: market, columns: filtered_columns })
    
    
    toggle_filtered_column_state = (id) ->
        if _.include(filtered_columns, id)
            filtered_columns = _.without(filtered_columns, id)
            toggle_source_column_state(source_columns_view, id, false)
        else
            filtered_columns.push(id)
            toggle_source_column_state(source_columns_view, id, true)
    
        check_active_columns()
    
        update()
    
    
    check_active_columns = ->
        active_columns = $('input:checked', source_columns_view)
    
        if active_columns.length >= max_active_columns
            disable_inactive_source_columns(source_columns_view)
        else
            enable_inactive_source_columns(source_columns_view)
        
        if active_columns.length <= min_active_columns
            disable_active_source_columns(source_columns_view)
        else
            enable_active_source_columns(source_columns_view)
        
    

    update_filtered_columns_order = (ordered_filtered_columns) ->
        filtered_columns = ordered_filtered_columns
        update()
        
    
    
    ready.then ->
        
        filtered_columns = filter_columns(columns(), filters(), scope.caches.table_filtered_columns(cache_key))
        
        cols = filters()['full'].reduce (memo, item) ->
            memo.push columns()[item.id] ; memo
        , []
        
        source_columns_view = make_source_columns_view(cols, filtered_columns)
        
        check_active_columns()
        
        source_columns_view.on 'change', 'input', (event) ->
          toggle_filtered_column_state(parseInt($(@).val()))
        
        deferred.resolve()
	

    deferred.promise(
        columns:    -> filtered_columns 
        view:       -> source_columns_view
        update_filtered_columns_order: update_filtered_columns_order
    )
    


$.extend scope,
    table_columns_filter: widget
