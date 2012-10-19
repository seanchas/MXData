root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (param, options = {}) ->
    deferred = new $.Deferred
    
    data = []
    
    $.ajax
        url: "#{scope.url_prefix}/emitters/#{param}/securities.json"
        data:
            'iss.meta': 'off'
            'iss.only': 'securities'
        dataType: 'json'
    .then (json) ->
        data.push(scope.merge_columns_and_data(json?.securities)...)
        deferred.resolve(data)
    
    deferred.promise({ data: data })


$.extend scope,
    emitter_securities: fetch
