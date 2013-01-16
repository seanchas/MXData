root        = @
scope       = root['mx']['data']


$           = jQuery


metadata    = undefined


render = (data) ->
    html = $('<dl>')
        .addClass('boards')
    
    _.each(data, render_row, html)
    
    html


render_row = (board) ->
    return unless !!board.is_traded
    
    $('<dt>')
        .html(board.title)
        .appendTo(@)
    
    $('<dd>')
        .html("C #{board.listed_from}")
        .appendTo(@)
    
    console.log board
    
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
