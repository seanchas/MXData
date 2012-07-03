root    = @
scope   = root['mx']['iss']
$       = jQuery

keys = [
    'indices'
    'currencies'
]

columns = ['SECID', 'BOARDID', 'SHORTNAME', 'DECIMALS']

fetch = ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/imicex/index.jsonp?callback=?"
        data:
            'iss.meta':             'off'
            'indices.columns':      columns.join(',')
            'currencies.columns':   columns.join(',')
        dataType: 'jsonp'
    .then (json) ->
        for key in keys
            data[key] = scope.merge_columns_and_data json?[key]
        deferred.resolve data
    
    deferred.promise({ data: data })


$.extend scope,
    bootstrap: _.once fetch
