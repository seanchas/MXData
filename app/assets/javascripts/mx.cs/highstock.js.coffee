##= require mx.iss

root    = @
scope   = root['mx']['cs']

$       = jQuery



fetch = (params, options = {}) ->
    deferred = new $.Deferred
    
    mx.iss.metadata().then (iss) ->
        
        find_board_group = (board) ->
            _.first(b.board_group_id for b in iss.boards when b.boardid == board)
        
        [engine, market, board, param]  = _.first(params).split(":")
        board_group                     = find_board_group board
        
        $.ajax
            url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/boardgroups/#{board_group}/securities/#{param}.hs?callback=?"
            data:
                's1.type': options.type ? 'line'
            dataType: 'jsonp'
        .then (json) ->
            deferred.resolve json
        
    
    deferred.promise()



$.extend scope,
    highstock: fetch
