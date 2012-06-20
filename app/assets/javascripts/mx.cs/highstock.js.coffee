##= require mx.iss

root    = @
scope   = root['mx']['cs']

$       = jQuery


metadata = mx.iss.metadata()


find_metadata = (boardid) ->
    board = _.detect(metadata.boards, (board) -> board.boardid == boardid)

    engine: _.detect(metadata.engines, (engine) -> engine.id == board.engine_id ).name
    market: _.detect(metadata.markets, (market) -> market.market_id == board.market_id ).market_name
    group:  board.board_group_id



fetch = (params, options = {}) ->
    deferred = new $.Deferred
    
    mx.iss.metadata().then (iss) ->
        
        find_board_group = (board) ->
            _.first(b.board_group_id for b in iss.boards when b.boardid == board)
        
        data =
            's1.type':  options.type        ? undefined
            'interval': options.interval    ? undefined
            'period':   options.period      ? undefined
            'candles':  options.candles     ? undefined
        
        { engine, market, board, id }   = _.first(params)
        board_group                     = find_board_group board

        params_to_compare = for param_to_compare in _.rest(params, 1)
            [param_to_compare.engine, param_to_compare.market, find_board_group(param_to_compare.board), param_to_compare.id].join(':')
        
        
        data.compare = params_to_compare.join(',') if _.size(params_to_compare) > 0
        
        
        $.ajax
            url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/boardgroups/#{board_group}/securities/#{id}.hs?callback=?"
            data: data
            dataType: 'jsonp'
        .then (json) ->
            deferred.resolve json
        
    
    deferred.promise()



fetch_2 = (param, options = {}) ->
    deferred    = new $.Deferred
    
    result = {}
    
    metadata.then ->
        
        [ board, id ]               = param.split(':')
        { engine, market, group }   = find_metadata board
        
        query_data =
            's1.type':      'candles'
            'interval':     options.interval
            'period':       options.period
            'candles':      options.candles
            'indicators':   options.technicals?.join(',')
        
        query_data = _.reduce(query_data, ((container, value, key) -> container[key] = value if value? ; container ), {})
        
        $.ajax
            url:        "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/boardgroups/#{group}/securities/#{id}.hs?callback=?"
            data:       query_data
            dataType:   'jsonp'
        .then (json) ->
            candles                 = json.candles[0]
            candles.candles_data    = candles.data
            candles.line_data       = _.map candles.data, (item) -> [item[0], item[4]]

            delete json.candles[0].data

            for key, value of json
                result[key] = value
            
            deferred.resolve result
    
    deferred.promise(result)



$.extend scope,
    highstock: fetch
    highstock_2: fetch_2
