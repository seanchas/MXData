root    = @
scope   = root['mx']['iss']
$       = jQuery


columns_cache = {}


cache_columns = (columns, engine, market, key) ->
    a = columns.security.reduce(((memo, record) -> memo[record[key]] = record ; memo), {})
    b = columns.marketdata.reduce(((memo, record) -> memo[record[key]] = record ; memo), {})

    columns_cache[engine + ':' + market + ':' + key] = $.extend(a, b)


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
        parse: (json, engine, market) ->
            result =
                hash:           (key) -> columns_cache[engine + ':' + market + ':' + key]
                security:       scope.merge_columns_and_data(json?.securities)
                marketdata:     scope.merge_columns_and_data(json?.marketdata)
            
            cache_columns(result, engine, market, 'id')
            cache_columns(result, engine, market, 'name')

            result
