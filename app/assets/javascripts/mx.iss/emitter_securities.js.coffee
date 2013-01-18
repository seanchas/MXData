root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'emitter_securities', arguments...


$.extend scope,
    emitter_securities: fetch

$.extend scope.fetch_descriptors,
    emitter_securities:
        cache_key: (id) ->
            "#{id}"
        url: (id) ->
            "/emitters/#{id}/securities.json"
        xhr_data: (id) ->
            'iss.only': 'securities'
        parse: (json, id) ->
            scope.merge_columns_and_data(json?.securities)
