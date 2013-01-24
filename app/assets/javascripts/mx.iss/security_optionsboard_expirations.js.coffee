root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_optionsboard_expirations', arguments...


$.extend scope,
    security_optionsboard_expirations: fetch

$.extend scope.fetch_descriptors,
    security_optionsboard_expirations:
        cache_key: (engine, market, board, id) ->
            "#{engine}:#{market}:#{board}:#{id}"
        url: (engine, market, board, id) ->
            "/engines/#{engine}/markets/#{market}/boards/#{board}/securities/#{id}/expirations.json"
        xhr_data: ->
            'iss.only': 'options'
        parse: (json) ->
            scope.merge_columns_and_data(json?.options)
