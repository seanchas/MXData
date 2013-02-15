$       = jQuery
scope   = @mx.data
data    = undefined


mappings = 
    engines:
        id:             'id'
        name:           'name'
        title:          'title'
    markets:
        id:             'market_id'
        name:           'market_name'
        title:          'market_title'
        engine_id:      'trade_engine_id'
    boards:
        id:             'boardid'
        title:          'board_title'
        trading:        (record) -> !!record.is_traded
        candles:        (record) -> !!record.has_candles
        market_id:      'market_id'
        engine_id:      'engine_id'
        boardgroup_id:  'board_group_id'
    boardgroups:
        id:             'board_group_id'
        default:        (record) -> !!record.is_default
        market_id:      'market_id'
        name:           'name'
        title:          'title'



engines             = undefined
engines_hash        = undefined
markets             = undefined
markets_hash        = undefined
boards              = undefined
boards_hash         = undefined
boardgroups         = undefined
boardgroups_hash    = undefined


prepared_tickers = {}


prepare_ticker = (ticker) ->
    [board, id] = ticker.split(':') ; board = scope.metadata().board(board)
    
    id:             id
    board:          board
    boardgroup:     board.boardgroup
    market:         board.market
    engine:         board.engine
    toString:    -> "#{id}:#{board.id}"


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
        [engines,       engines_hash]       = populate_data(mappings.engines,       data.result.data.engines)
        [markets,       markets_hash]       = populate_data(mappings.markets,       data.result.data.markets)
        [boards,        boards_hash]        = populate_data(mappings.boards,        data.result.data.boards)
        [boardgroups,   boardgroups_hash]   = populate_data(mappings.boardgroups,   data.result.data.boardgroups)
        
        _.each(markets_hash, (market) -> market.engine = engines_hash[market.engine_id])
        _.each(boards_hash, (board) -> board.market = markets_hash[board.market_id] ; board.engine = engines_hash[board.engine_id] ; board.boardgroup = boardgroups_hash[board.boardgroup_id])
        
        deferred.resolve()

    deferred.promise
        engines:         -> engines
        engine:     (id) -> engines_hash[id]
        markets:         -> markets
        market:     (id) -> markets_hash[id]
        boards:          -> boards
        board:      (id) -> boards_hash[id]
        ticker: (ticker) -> prepared_tickers[ticker] ?= prepare_ticker(ticker)


$.extend scope,
    metadata: _.once metadata
