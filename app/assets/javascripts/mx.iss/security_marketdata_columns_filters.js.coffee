root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_marketdata_columns_filters', arguments...


$.extend scope,
    security_marketdata_columns_filters: fetch

$.extend scope.fetch_descriptors,
    security_marketdata_columns_filters:
        cache_key: (engine, market) ->
            "#{engine}:#{market}"
        url: (engine, market) ->
            "/engines/#{engine}/markets/#{market}/securities/columns/filters.json"
        xhr_data: ->
            'iss.only': 'filters'
        parse: (json) ->
            scope.merge_columns_and_data(json?.filters)
