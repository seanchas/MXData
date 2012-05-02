##= require mx.iss

root    = @
scope   = root['mx']['cs']

$       = jQuery



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



$.extend scope,
    highstock: fetch
