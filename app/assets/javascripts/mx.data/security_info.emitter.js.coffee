root    = @
scope   = root['mx']['data']


$       = jQuery


metadata        = mx.data.metadata()
emitter_columns = mx.iss.emitter_columns()


security_emitter_id_column_name = 'EMITTER_ID'


render = (data) ->
    html = $('<dl>')
        .addClass('emitter')
    
    $('<dt>')
        .addClass('title')
        .html(data.TITLE)
        .appendTo(html)
    
    _.each(emitter_columns.result.data, (column) -> render_row(column, data, html))
    
    html


render_row = (column, data, html) ->
    $('<dt>')
        .html(column.short_title)
        .appendTo(html)
    
    $('<dd>')
        .html(data[column.name])
        .appendTo(html)
    
    html


widget = (ticker) ->
    
    deferred = new $.Deferred
    
    html        = undefined
    access      = undefined
    error       = undefined
    id          = undefined
    
    security    = mx.iss.security ticker
    
    ready       = $.when metadata, emitter_columns, security
    
    
    reload = ->
        emitter = mx.iss.emitter id
        
        emitter.then ->
            
            html    = undefined
            error   = undefined
            
            emitter = emitter.result
            access  = emitter['x-marker']
            html    = render(emitter.data)  unless  emitter.error?
            error   = emitter.error         if      emitter.error?
            
            $(window).trigger "security-info:emitter:loaded:#{ticker}"
            
    
    ready.then ->
        
        security    = security.result
        id          = _.find(security.data.description, (column) -> column.name == security_emitter_id_column_name).value
        
        reload()
        
        deferred.resolve()
    
    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error


$.extend scope,
    security_info_emitter: widget
