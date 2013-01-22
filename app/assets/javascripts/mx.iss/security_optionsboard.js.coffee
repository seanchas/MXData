root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_optionsboard', arguments...


$.extend scope,
    security_optionsboard: fetch

$.extend scope.fetch_descriptors,
    security_optionsboard:
        cache_key: (engine, market, id) ->
            "#{engine}:#{market}:#{id}"
        url: (engine, market, id) ->
            "/engines/#{engine}/markets/#{market}/securities/#{id}/optionboard.json"
        xhr_data: ->
            'iss.only': 'optionboard'
            'lastdate': '2013-03-14'
        parse: (json) ->
            scope.merge_columns_and_data(json?.optionboard)
