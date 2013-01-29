root    = @
scope   = root['mx']['data']


$       = jQuery


metadata        = undefined
security_types  = undefined


security_emitter_id_column_name = 'EMITTER_ID'


render = (data) ->
    html = $('<table>')
        .addClass('common')
        .html('<tbody></tbody>')
    
    table_body = $('tbody', html)
    
    grouped_records = _.reduce(data, (memo, record) ->
        (memo[parseInt record.SECURITY_TYPE_ID] ?= []).push(record) ; memo
    , {})
    
    
    _.each(security_types.result.data, (security_type) ->
        records = grouped_records[security_type.id] ; return unless records?
        render_row security_type, records, table_body
    )
    
    html


render_row = (security_type, data, html) ->
    row = $('<tr>')
        .appendTo(html)
    
    $('<th>')
        .html(security_type.title)
        .appendTo(row)
    
    $('<td>')
        .html(_.pluck(data, 'NAME').join(', '))
        .appendTo(row)
    
    html


widget = (ticker, options = {}) ->
    
    deferred = new $.Deferred
    
    after_render_callbacks   = new $.Callbacks

    html        = undefined
    access      = undefined
    error       = undefined
    id          = undefined
    
    [board, secid] = ticker.split(':')
    
    security    = mx.iss.security secid
    
    ready       = $.when metadata, security_types, security
    
    
    metadata        ?= mx.data.metadata()
    security_types  ?= mx.iss.security_types()
    
    
    [].concat(options.after_render).forEach after_render_callbacks.add if options.after_render?


    reload = ->
        securities = mx.iss.emitter_securities id
        
        securities.then ->
            
            html    = undefined
            error   = undefined

            securities  = securities.result
            access      = securities['x-marker']
            html        = render(securities.data)   unless  securities.error? or securities.data.length == 0
            error       = securities.error          if      securities.error?
            
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
    security_info_emitter_securities: widget
