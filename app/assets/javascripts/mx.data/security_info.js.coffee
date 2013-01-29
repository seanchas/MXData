##= require_self
##= require_tree ./security_info

root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined


render_description = (description, html) ->
    $('.description_title').toggleClass('active', description.html()?)
    $('.description_container', html).html(description.html() ? '')

render_emitter = (emitter, html) ->
    $('.emitter_title').toggleClass('active', emitter.html()?)
    $('.emitter_container', html).html(emitter.html() ? '').toggle(emitter.html()?)

render_emitter_securities = (emitter_securities, html) ->
    $('.emitter_securities_title').toggleClass('active', emitter_securities.html()?)
    $('.emitter_securities_container', html).html(emitter_securities.html() ? '').toggle(emitter_securities.html()?)

render_boards = (boards, html) ->
    $('.boards_title').toggleClass('active', boards.html()?)
    $('.boards_container', html).html(boards.html() ? '').toggle(boards.html()?)


render_orderbook = (orderbook, html) ->
    $('.orderbook_title').toggleClass('active', orderbook.html()?)
    $('.orderbook_container', html).html(orderbook.html() ? '')



render  = ->
    ich.security_info()



widget = (ticker, options = {}) ->
    container   = $(options.container) ; container = undefined if container.length == 0

    deferred    = new $.Deferred
    
    [board, id] = ticker.split(':')
    
    boards              = undefined
    emitter             = undefined
    emitter_securities  = undefined
    orderbook           = undefined
    
    metadata           ?= mx.data.metadata()
    
    html                = undefined
    
    show                = -> html.show()
    hide                = -> html.hide()
    
    ready       = $.when metadata
    
    ready.then ->

        ###

        $(window).on "security-info:description:loaded:#{ticker}", ->
            render_description $('.description_container', container), description

        $(window).on "security-info:emitter:loaded:#{id}", ->
            render_emitter $('.emitter_container', container), emitter

        $(window).on "security-info:emitter-securities:loaded:#{id}", ->
            render_emitter $('.emitter_securities_container', container), emitter_securities

        $(window).on "security-info:boards:loaded:#{id}", ->
            render_boards $('.boards_container', container), boards

        $(window).on "security-info:orderbook:loaded:#{ticker}", ->
            render_orderbook $('.orderbook_container', container), orderbook

        description         = mx.data.security_info_description(ticker)
        emitter             = mx.data.security_info_emitter(id)
        emitter_securities  = mx.data.security_info_emitter_securities(id)
        boards              = mx.data.security_info_boards(id)
        orderbook           = mx.data.security_info_orderbook(ticker)
        
        ###
        
        html = render() ; container.html(html) if container?
        
        description         = mx.data.security_info_description(ticker,         { after_render: -> render_description(description, html) })
        orderbook           = mx.data.security_info_orderbook(ticker,           { after_render: -> render_orderbook(orderbook, html) })
        emitter             = mx.data.security_info_emitter(ticker,             { after_render: -> render_emitter(emitter, html) })
        boards              = mx.data.security_info_boards(ticker,              { after_render: -> render_boards(boards, html) })
        emitter_securities  = mx.data.security_info_emitter_securities(ticker,  { after_render: -> render_emitter_securities(emitter_securities, html) })

        deferred.resolve()
    

    deferred.promise
        html:   -> html
        show:      show
        hide:      hide


$.extend scope,
    security_info: widget
