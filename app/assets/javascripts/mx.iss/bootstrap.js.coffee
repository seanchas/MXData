root    = @
scope   = root['mx']['iss']
$       = jQuery

keys = [
    'indices'
    'currencies'
]

columns = ['BOARDID', 'SECID']

fetch = ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/imicex/index.json"
        data:
            'iss.meta':             'off'
            'indices.columns':      columns.join(',')
            'currencies.columns':   columns.join(',')
    .then (json) ->
        for key in keys
            data[key] = scope.merge_columns_and_data json?[key]
        deferred.resolve data
    
    deferred.promise({ data: data })


$.extend scope,
    bootstrap: _.once fetch
