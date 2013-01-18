root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_marketdata', arguments...


$.extend scope,
    security_marketdata: fetch

$.extend scope.fetch_descriptors,
    security_marketdata:
        cache_key: (engine, market, board, id) ->
            "#{engine}:#{market}:#{board}:#{id}"
        url: (engine, market, board, id) ->
            "/engines/#{engine}/markets/#{market}/boards/#{board}/securities/#{id}.json"
        xhr_data: ->
            'iss.only': 'securities,marketdata,dataversion'
        parse: (json) ->
            security:       scope.merge_columns_and_data(json?.securities)[0]
            marketdata:     scope.merge_columns_and_data(json?.marketdata)[0]
            dataversion:    scope.merge_columns_and_data(json?.dataversion)[0]
