root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_indices', arguments...


$.extend scope,
    security_indices: fetch

$.extend scope.fetch_descriptors,
    security_indices:
        cache_key: (id) ->
            "#{id}"
        url: (id) ->
            "/securities/#{id}/indices.json"
        xhr_data: (id) ->
            'iss.only': 'indices'
        parse: (json, id) ->
            scope.merge_columns_and_data(json?.indices)
