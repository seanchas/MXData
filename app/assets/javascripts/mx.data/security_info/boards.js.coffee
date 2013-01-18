root        = @
scope       = root['mx']['data']


$           = jQuery


metadata    = undefined


iss_date_format = d3.time.format('%Y-%m-%d')


locales =
    listed_from:
        ru: 'с'
        en: 'from'
    date:
        ru: d3.time.format('%d.%m.%Y')
        en: d3.time.format('%m/%d/%Y')


render = (data) ->
    html = $('<table>')
        .html('<tbody></tbody>')
    
    table_body = $('tbody', html)
    
    _.each(data, render_row, table_body)
    
    html


render_row = (board) ->
    return unless !!board.is_traded
    
    row = $('<tr>')
        .appendTo(@)
    
    $('<th>')
        .html(board.title)
        .appendTo(row)
    
    value = locales.date[mx.locale()] iss_date_format.parse(board.listed_from)
    
    $('<td>')
        .html("#{locales.listed_from[mx.locale()]} #{value}")
        .appendTo(row)
    
    @


widget = (ticker) ->
    
    deferred = new $.Deferred
    
    access  = undefined
    html    = undefined
    error   = undefined
    
    
    metadata ?= mx.data.metadata()
    
    
    ready   = $.when metadata
    
    
    reload = ->
        security = mx.iss.security ticker
        
        security.then ->
            
            html        = undefined
            error       = undefined

            security    = security.result
            access      = security['x-marker']
            html        = render(security.data.boards)  unless  security.error?
            error       = security.error                if      security.error?
            
            
            $(window).trigger "security-info:boards:loaded:#{ticker}"
        
    
    
    ready.then ->
        
        reload()
        
        deferred.resolve()
    
    
    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error



$.extend scope,
    security_info_boards: widget
