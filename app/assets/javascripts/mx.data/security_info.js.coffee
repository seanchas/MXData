root    = @
scope   = root['mx']['data']


$       = jQuery



metadata = mx.data.metadata()


render_boards = (container, boards) ->
    container.html(boards.html() ? '')

render_emitter = (container, emitter) ->
    container.html(emitter.html() ? '')

render_orderbook = (container, orderbook) ->
    container.html(orderbook.html() ? '')


widget = (container, ticker) ->
    container   = $(container) ; return if container.length == 0

    deferred    = new $.Deferred
    
    [board, id] = ticker.split(':')
    
    boards      = undefined
    emitter     = undefined
    orderbook   = undefined
    
    ready       = $.when metadata
    
    ready.then ->

        $(window).on "security-info:boards:loaded:#{id}", ->
            render_boards $('.boards_container', container), boards

        $(window).on "security-info:emitter:loaded:#{id}", ->
            render_emitter $('.emitter_container', container), emitter

        $(window).on "security-info:orderbook:loaded:#{ticker}", ->
            render_orderbook $('.orderbook_container', container), orderbook

        emitter     = mx.data.security_info_emitter(id)
        boards      = mx.data.security_info_boards(id)
        orderbook   = mx.data.security_info_orderbook(ticker)

        deferred.resolve()
    

    deferred.promise()


$.extend scope,
    security_info: widget
