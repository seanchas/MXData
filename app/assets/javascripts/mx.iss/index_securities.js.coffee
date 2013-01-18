root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'index_securities', arguments...


$.extend scope,
    index_securities: fetch

$.extend scope.fetch_descriptors,
    index_securities:
        cache_key: (engine, market, id) ->
            "#{engine}:#{market}:#{id}"
        url: (engine, market, id) ->
            "/statistics/engines/#{engine}/markets/#{market}/analytics/#{id}/indices.json"
        xhr_data: ->
            'iss.only': 'analytics'
        parse: (json) ->
            scope.merge_columns_and_data(json?.analytics)
