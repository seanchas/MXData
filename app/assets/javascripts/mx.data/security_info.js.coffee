root    = @
scope   = root['mx']['data']


$       = jQuery



metadata = mx.data.metadata()


render_orderbook = (container, orderbook) ->
    container.html(orderbook.html() ? '')


widget = (container, ticker) ->
    container   = $(container) ; return if container.length == 0

    deferred    = new $.Deferred
    
    orderbook   = mx.data.security_info_orderbook(ticker)
        
    ready       = $.when(orderbook)
    
    ready.then ->

        $(window).on "security-info:orderbook:loaded:#{ticker}", ->
            render_orderbook $('.orderbook_container', container), orderbook

        deferred.resolve()
    

    deferred.promise()


$.extend scope,
    security_info: widget
