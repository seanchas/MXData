root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (options = {}) ->
    deferred = new $.Deferred
    
    data = []
    
    $.ajax
        url: "#{scope.url_prefix}/emitters/columns.json"
        data:
            'iss.meta': 'off'
            'iss.only': 'securities'
        dataType: 'json'
    .then (json) ->
        data.push(scope.merge_columns_and_data(json?.emitter)...)
        deferred.resolve(data)
    
    deferred.promise({ data: data })


$.extend scope,
    emitter_columns: fetch
