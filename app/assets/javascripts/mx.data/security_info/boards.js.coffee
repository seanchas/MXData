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
        .addClass('common boards')
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


widget = (ticker, options = {}) ->
    
    deferred = new $.Deferred
    
    after_render_callbacks   = new $.Callbacks

    access  = undefined
    html    = undefined
    error   = undefined
    
    [board, id] = ticker.split(':')
    
    
    metadata ?= mx.data.metadata()
    
    
    ready   = $.when metadata
    

    [].concat(options.after_render).forEach after_render_callbacks.add if options.after_render?
    

    reload = ->
        security = mx.iss.security id
        
        security.then ->
            
            html        = undefined
            error       = undefined

            security    = security.result
            access      = security['x-marker']
            html        = render(security.data.boards)  unless  security.error?
            error       = security.error                if      security.error?
            
            after_render_callbacks.fire()
            
            deferred.resolve()
        
    
    
    ready.then ->
        
        reload()
    
    
    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error



$.extend scope,
    security_info_boards: widget
