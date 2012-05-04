root    = @
scope   = root['mx']['iss']
$       = jQuery

keys = [
    'indices'
    'currencies'
]

fetch = ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/imicex/index.jsonp?callback=?"
        data:
            'iss.meta':             'off'
            'indices.columns':      'SECID,BOARDID'
            'currencies.columns':   'SECID,BOARDID'
        dataType: 'jsonp'
    .then (json) ->
        for key in keys
            data[key] = scope.merge_columns_and_data json?[key]
        deferred.resolve data
    
    deferred.promise(data)


$.extend scope,
    bootstrap: _.once fetch
