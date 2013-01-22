root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_optionsboard_columns', arguments...


$.extend scope,
    security_optionsboard_columns: fetch

$.extend scope.fetch_descriptors,
    security_optionsboard_columns:
        cache_key: (engine, market) ->
            "#{engine}:#{market}"
        url: (engine, market, id) ->
            "/engines/#{engine}/markets/#{market}/securities/optionboard/columns.json"
        xhr_data: ->
            'iss.only': 'optionboard'
        parse: (json) ->
            scope.merge_columns_and_data(json?.optionboard)
