root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'emitter', arguments...


$.extend scope,
    emitter: fetch


$.extend scope.fetch_descriptors,
    emitter:
        cache_key: (id) ->
            "#{id}"
        url: (id) ->
            "/emitters/#{id}.json"
        xhr_data: ->
            'iss.only': 'emitter'
        parse: (json, engine, market, board, id) ->
            scope.merge_columns_and_data(json?.emitter)[0]
