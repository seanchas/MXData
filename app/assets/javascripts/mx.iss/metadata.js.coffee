root    = @
scope   = root['mx']['iss']
$       = jQuery


keys = [
    'engines'
    'markets'
    'boards'
    'durations'
]


fetch = ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}.jsonp?callback=?"
        data:
            'iss.meta': 'off'
        dataType: 'jsonp'
    .then (json) ->
        for key in keys
            data[key] = scope.merge_columns_and_data json?[key]
        deferred.resolve data
    
    deferred.promise(data)


$.extend scope,
    metadata: _.once fetch
