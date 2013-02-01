$       = jQuery
scope   = @mx.data
data    = undefined


mappings = 
    engines:
        id:         'id'
        name:       'name'
        title:      'title'
    markets:
        id:         'market_id'
        name:       'market_name'
        title:      'market_title'
        engine_id:  'trade_engine_id'
    boards:
        id:         'boardid'
        title:      'board_title'
        trading:    (record) -> !!record.is_traded
        market_id:  'market_id'
        engine_id:  'engine_id'



engines         = undefined
engines_hash    = undefined
markets         = undefined
markets_hash    = undefined
boards          = undefined
boards_hash     = undefined



populate_data = (mapping, data) ->
    hash = _.reduce(data,
        (memo, record) ->
            memo[record[mapping.id]] = _.reduce(mapping, ((memo, value, key) -> ( memo[key] = if _.isFunction(value) then value(record) else record[value] ) ; memo), {})
            memo
        , {}
    )
    
    array = _.map(data, (record) -> hash[record[mapping.id]])

    [array, hash]


metadata = ->
    
    deferred    = new $.Deferred
    
    data       ?= mx.iss.metadata()
    
    ready       = $.when(data)
    
    ready.then ->
        [engines, engines_hash] = populate_data(mappings.engines,   data.result.data.engines)
        [markets, markets_hash] = populate_data(mappings.markets,   data.result.data.markets)
        [boards,  boards_hash]  = populate_data(mappings.boards,    data.result.data.boards)
        
        _.each(markets_hash, (market) -> market.engine = engines_hash[market.engine_id])
        _.each(boards_hash, (board) -> board.market = markets_hash[board.market_id] ; board.engine = engines_hash[board.engine_id])
        
        
        
        deferred.resolve()

    deferred.promise
        engines:         -> engines
        engine:     (id) -> engines_hash[id]
        markets:         -> markets
        market:     (id) -> markets_hash[id]
        boards:          -> boards
        board:      (id) -> boards_hash[id]


$.extend scope,
    metadata: metadata
