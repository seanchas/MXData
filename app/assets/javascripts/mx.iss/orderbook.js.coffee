root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'orderbook', arguments...


$.extend scope,
    orderbook: fetch


$.extend scope.fetch_descriptors,
    orderbook:
        cache_key: (engine, market, board, id) ->
            "#{engine}:#{market}:#{board}:#{id}"
        url: (engine, market, board, id) ->
            "/engines/#{engine}/markets/#{market}/boards/#{board}/securities/#{id}/orderbook.json"
        xhr_data: (engine, market, board, id) ->
            'iss.only': 'orderbook'
        parse: (json, engine, market, board, id) ->
            scope.merge_columns_and_data(json?.orderbook)
