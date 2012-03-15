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
            's1.type': options.type ? 'line'
            'interval': 24
            'period': '2y'
        
        [engine, market, board, param]  = _.first(params).split(":")
        board_group                     = find_board_group board

        params_to_compare = for param_to_compare in _.rest(params, 1)
            [e, m, b, p] = param_to_compare.split(":")
            bg = find_board_group b
            [e, m, bg, p].join(":")
        
        
        data.compare = params_to_compare.join(',') if _.size(params_to_compare) > 0
        
        
        $.ajax
            url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/boardgroups/#{board_group}/securities/#{param}.hs?callback=?"
            data: data
            dataType: 'jsonp'
        .then (json) ->
            deferred.resolve json
        
    
    deferred.promise()



$.extend scope,
    highstock: fetch
