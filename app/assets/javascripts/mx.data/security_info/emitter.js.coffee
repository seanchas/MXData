root    = @
scope   = root['mx']['data']


$       = jQuery


metadata        = undefined
emitter_columns = undefined


security_emitter_id_column_name = 'EMITTER_ID'


render = (data) ->
    html = $('<table>')
        .addClass('common')
        .html('<thead></thead><tbody></tbody>')
    
    table_head = $('thead', html)
    table_body = $('tbody', html)
    
    render_table_head_row(data.TITLE, table_head)
    
    _.each(emitter_columns.result.data, (column) -> render_table_body_row(column, data, html))
    
    html


render_table_head_row = (data, html) ->
    row = $('<tr>')
        .appendTo(html)
    
    $('<th>')
        .attr('colspan', 2)
        .html(data)
        .appendTo(row)
    
    html


render_table_body_row = (column, data, html) ->
    row = $('<tr>')
        .appendTo(html)

    $('<th>')
        .html(column.short_title)
        .appendTo(row)
    
    $('<td>')
        .html(data[column.name])
        .appendTo(row)
    
    html


widget = (ticker, options = {}) ->
    
    deferred = new $.Deferred
    
    after_render_callbacks   = new $.Callbacks

    html        = undefined
    access      = undefined
    error       = undefined
    id          = undefined

    [board, secid]  = ticker.split(':')
    
    security    = mx.iss.security secid
    
    metadata        ?= mx.data.metadata()
    emitter_columns ?= mx.iss.emitter_columns()

    ready       = $.when metadata, emitter_columns, security
    
    
    [].concat(options.after_render).forEach after_render_callbacks.add if options.after_render?


    reload = ->
        emitter = mx.iss.emitter id
        
        emitter.then ->
            
            html    = undefined
            error   = undefined
            
            emitter = emitter.result
            access  = emitter['x-marker']
            html    = render(emitter.data)  unless  emitter.error?
            error   = emitter.error         if      emitter.error?
            
            after_render_callbacks.fire()
            
            deferred.resolve()
    
    
    ready.then ->
        
        security    = security.result
        id          = _.find(security.data.description, (column) -> column.name == security_emitter_id_column_name)?.value
        
        unless id?
            after_render_callbacks.fire()
            deferred.reject()
        
        reload() if id?
        

    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error


$.extend scope,
    security_info_emitter: widget
