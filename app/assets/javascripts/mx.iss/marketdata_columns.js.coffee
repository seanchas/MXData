root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (securities, marketdata) ->
    


fetch = (params) ->
    deferred = new $.Deferred
    
    [engine, market] = params.split(":")
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities/columns.jsonp?callback=?"
        data:
            'iss.meta': 'off'
        dataType: 'jsonp'
    .then (json) ->
        securities = scope.merge_columns_and_data(json?.securities)
        marketdata = scope.merge_columns_and_data(json?.marketdata)
        
        console.log prepare securities, marketdata
    
    deferred.promise()


$.extend scope,
    marketdata_columns: fetch
