root    = @
scope   = root['mx']['data']


$       = jQuery


metadata        = undefined
security_types  = undefined


security_emitter_id_column_name = 'EMITTER_ID'


render = (data) ->
    html = $('<table>')
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


widget = (ticker) ->
    
    deferred = new $.Deferred
    
    html        = undefined
    access      = undefined
    error       = undefined
    id          = undefined
    
    security    = mx.iss.security ticker
    
    ready       = $.when metadata, security_types, security
    
    
    metadata        ?= mx.data.metadata()
    security_types  ?= mx.iss.security_types()
    
    
    reload = ->
        securities = mx.iss.emitter_securities id
        
        securities.then ->
            
            html    = undefined
            error   = undefined

            securities  = securities.result
            access      = securities['x-marker']
            html        = render(securities.data)   unless  securities.error? or securities.data.length == 0
            error       = securities.error          if      securities.error?
            
            $(window).trigger "security-info:emitter-securities:loaded:#{ticker}"
            
    
    ready.then ->
        
        security    = security.result
        id          = _.find(security.data.description, (column) -> column.name == security_emitter_id_column_name)?.value
        
        $(window).trigger "security-info:emitter-securities:invalid:#{ticker}" unless id?

        reload() if id?
        
        deferred.resolve()
    

    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error


$.extend scope,
    security_info_emitter_securities: widget
