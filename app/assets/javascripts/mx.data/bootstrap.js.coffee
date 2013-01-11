root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.bootstrap')


keys = ['indices', 'currencies']


fetch = (tables) ->
    return if cache.get('complete')

    bootstrap   = mx.iss.bootstrap()
    metadata    = mx.data.metadata()

    ready = $.when(bootstrap, metadata, tables...)

    
    ready.then ->
        
        _.chain(keys)
            .reduce(
                (memo, key) -> 
                    memo.push(bootstrap.data[key]...) ; memo
                , []
            )
            .each(
                (ticker) ->
                    board = metadata.board(ticker.BOARDID)
                    $(window).trigger "global:table:security:add:#{board.engine.name}:#{board.market.name}", { ticker: "#{ticker.BOARDID}:#{ticker.SECID}" }
            )
        
        _.each keys, (key) ->
            ticker = bootstrap.data[key][0]
            $(window).trigger "security:to:chart", { id: ticker.SECID, board: ticker.BOARDID }
        
        cache.set('complete', true)


$.extend scope,
    bootstrap: fetch
