root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_marketdata_columns', arguments...


$.extend scope,
    security_marketdata_columns: fetch

$.extend scope.fetch_descriptors,
    security_marketdata_columns:
        cache_key: (engine, market) ->
            "#{engine}:#{market}"
        url: (engine, market) ->
            "/engines/#{engine}/markets/#{market}/securities/columns.json"
        xhr_data: ->
            'iss.only': 'securities,marketdata'
        parse: (json) ->
            security:       scope.merge_columns_and_data(json?.securities)
            marketdata:     scope.merge_columns_and_data(json?.marketdata)
