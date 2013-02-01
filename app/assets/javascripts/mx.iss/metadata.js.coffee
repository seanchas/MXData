$       = jQuery
scope   = @mx.iss


keys = [
    'engines'
    'markets'
    'boards'
    'durations'
]


fetch = ->
    scope.fetch 'metadata', arguments...


$.extend scope,
    metadata: fetch


$.extend scope.fetch_descriptors,
    metadata:
        cache_key: ->
            ""
        url: ->
            "/index.json"
        xhr_data: ->
            'iss.only': keys.join(',')
        parse: (json) ->
            keys.reduce(((memo, key) -> memo[key] = scope.merge_columns_and_data(json?[key]) ; memo), {})
