root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_optionsboard', arguments...


$.extend scope,
    security_optionsboard: fetch

$.extend scope.fetch_descriptors,
    security_optionsboard:
        cache_key: (engine, market, board, id, date) ->
            "#{engine}:#{market}:#{board}:#{id}:#{date}"
        url: (engine, market, board, id) ->
            "/engines/#{engine}/markets/#{market}/boards/#{board}/securities/#{id}/optionboard.json"
        xhr_data: (engine, market, board, id, date) ->
            'iss.only': 'call,put'
            'lastdate': date
        parse: (json) ->
            call:   scope.merge_columns_and_data(json?.call)
            put:    scope.merge_columns_and_data(json?.put)
