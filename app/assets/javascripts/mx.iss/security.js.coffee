root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch2 = (ticker, options = {}) ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/securities/#{ticker}.json"
        data:
            'iss.meta': 'off'
            'iss.only': 'description,boards'
        dataType: 'json'
    .then (json) ->
        data.description    = scope.merge_columns_and_data(json?.description)
        data.boards         = scope.merge_columns_and_data(json?.boards)
        deferred.resolve(data)
    
    deferred.promise({ data: data })


fetch = ->
    scope.fetch 'security', arguments...


$.extend scope,
    security: fetch

$.extend scope.fetch_descriptors,
    security:
        cache_key: (id) ->
            "#{id}"
        url: (id) ->
            "/securities/#{id}.json"
        xhr_data: ->
            'iss.only': 'description,boards'
        parse: (json, id) ->
            description:    scope.merge_columns_and_data(json?.description)
            boards:         scope.merge_columns_and_data(json?.boards)