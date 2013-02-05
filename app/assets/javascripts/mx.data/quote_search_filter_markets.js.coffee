root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined



cache = kizzy('data.quote_search.filter_markets')



make_view = (values) ->
    view = $('<ul>')
        .addClass('markets clearfix')
    
    _.each(metadata.markets, (market) -> make_market_view(market, view, values))
    
    view


make_market_view = (market, container, values) ->
    view = $('<li>')
    
    label = $('<label>')
        .html(market.market_title)
    
    key = [market.trade_engine_name, market.market_name].join(':')
    
    checkbox = $('<input>')
        .attr('type', 'checkbox')
        .attr('checked', _.isEmpty(values) or _.include(values, key))
        .val(key)
        .prependTo(label)
    
    view
        .append(label)
        .appendTo(container)


widget = ->
    
    deferred = new $.Deferred

    cache_key = ''
    view = undefined    
    
    metadata ?= mx.iss.metadata()
    
    ready = $.when(metadata)
    
    
    update = (values) ->
        cache.set(cache_key, values)
    
    
    update_filter_markets_cache = ->
        update _.map($('input:checked', view), (checkbox) -> $(checkbox).val())
        check_markets_margins()
    
    
    check_markets_margins = ->
        checked_markets = $('input:checked', view);
        if checked_markets.length == 1
            checked_markets.attr('disabled', true) 
        else
            checked_markets.attr('disabled', false)
    
    
    ready.then ->
        
        view = make_view(cache.get(cache_key) || [])
        check_markets_margins()
        
        view.on 'change', 'input', update_filter_markets_cache
        
        deferred.resolve()
        
    
    deferred.promise({
        view:   -> view
        values: -> cache.get(cache_key)
    })



$.extend scope,
    quote_search_filter_markets: widget
