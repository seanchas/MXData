root    = @
scope   = root['mx']['data']


$       = jQuery


cache           = kizzy('data.bootstrap')
tables_cache    = -> kizzy('data.table')
chart_cache     = kizzy('data.chart.instruments')


keys = ['indices', 'currencies']


deferred = new $.Deferred


fetch = ->
    if cache.get('complete')
        deferred.resolve() ; return deferred.promise()

    bootstrap   = mx.iss.bootstrap()
    metadata    = mx.data.metadata()

    ready = $.when(bootstrap, metadata)

    
    ready.then ->
        
        console.log 'bootstrapping'
        
        
        to_table = (ticker) ->
            board   = metadata.board(ticker.BOARDID)
            key     = "#{board.engine.name}:#{board.market.name}:securities"
            value   = "#{board.id}:#{ticker.SECID}"
            
            values  = tables_cache().get(key) || [] ; values.push(value)
            tables_cache().set(key, values)
        
        to_chart = (ticker) ->
            key     = ""
            value   = { board: ticker.BOARDID, id: ticker.SECID }
            
            values  = scope.caches.chart_instruments() || [] ; values.push(value)
            
            console.log values
            scope.caches.chart_instruments(values)
        
        keys.forEach (key) ->
            
            chart_empty = true
            
            bootstrap.data[key].forEach (ticker) ->
                to_table ticker
                to_chart ticker if chart_empty
                
                chart_empty = false
        
        cache.set('complete', true)

        deferred.resolve()
    

    deferred.promise()


$.extend scope,
    bootstrap: fetch
