root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (param, options = {}) ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/emitters/#{param}.json"
        data:
            'iss.meta': 'off'
            'iss.only': 'emitter'
        dataType: 'json'
    .then (json) ->
        data[key] = value for key, value of _.first(scope.merge_columns_and_data(json?.emitter))
        deferred.resolve(data)
    
    deferred.promise({ data: data })


$.extend scope,
    emitter: fetch
