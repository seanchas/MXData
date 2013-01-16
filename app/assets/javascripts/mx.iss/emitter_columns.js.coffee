root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'emitter_columns', arguments...


$.extend scope,
    emitter_columns: fetch


$.extend scope.fetch_descriptors,
    emitter_columns:
        cache_key: (id) ->
            "#{id}"
        url: (id) ->
            "/emitters/columns.json"
        xhr_data: ->
            'iss.only': 'emitter'
        parse: (json, engine, market, board, id) ->
            scope.merge_columns_and_data(json?.emitter)
