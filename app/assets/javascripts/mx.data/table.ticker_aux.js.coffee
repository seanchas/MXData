root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined


widget = (ticker, options = {}) ->
    container = $(options.container) ; container = undefined if container.length == 0
    
    deferred                = new $.Deferred
    after_render_callbacks  = new $.Callbacks
    
    [].concat(options.after_render).forEach after_render_callbacks.add if options.after_render?
    
    [board, id]     = ticker.split(':')
    html            = ich.table_ticker_aux()
    
    show = -> html.show() if html?
    hide = -> html.hide() if html?

    metadata               ?= mx.data.metadata()

    security_description    = undefined
    options_board           = undefined
    
    ready   = $.when metadata
    
    tabs    = shared.tabs(html)
    
    on_tab_activate = (key) ->
        switch key
            when 'security_description'
                security_description.show() if security_description?
                options_board.hide()        if options_board?
                                
            when 'options_board'
                options_board.show()        if options_board?
                security_description.hide() if security_description?

            when 'add_to_chart'
                $(window).trigger 'security:to:chart', ticker

            when 'remove_from_chart'
                $(window).trigger 'security:from:chart', ticker

            when 'remove_from_table'
                $(window).trigger "global:table:security:remove:#{board.engine.name}:#{board.market.name}", { ticker: ticker }

    ready.then ->
        board                   = metadata.board board
        security_description    = mx.data.security_info(ticker)
        
        if board.market.name == 'forts'
            tabs.tab('options_board').show()
            options_board = mx.data.optionsboard(ticker)
        
        $.when(security_description, options_board).then ->
            
            tabs.content('security_description').html(security_description.html())

            if options_board?
                tabs.content('options_board').html(options_board.html())
                $('.expirations', tabs.tab('options_board')).html(options_board.expiration_chooser().html())
            
            tabs.on_activate on_tab_activate

            tabs.activate('security_description')
        
            container.html(html) if container?
        
        deferred.resolve()
    
    deferred.promise
        after_render:      after_render_callbacks.add
        html:           -> html
        show:              show
        hide:              hide


$.extend scope,
    table_ticker_aux: widget
