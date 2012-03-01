root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (securities, marketdata) ->
    securities = _.reduce securities, ((memo, record) -> memo[record.id] = record; memo), {}
    marketdata = _.reduce marketdata, ((memo, record) -> memo[record.id] = record; memo), {}
    _.extend securities, marketdata


fetch = (engine, market) ->
    deferred = new $.Deferred
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities/columns.jsonp?callback=?"
        data:
            'iss.meta': 'off'
            'iss.only': 'securities,marketdata'
        dataType: 'jsonp'
    .then (json) ->
        deferred.resolve prepare scope.merge_columns_and_data(json?.securities), scope.merge_columns_and_data(json?.marketdata)
    
    deferred.promise()


$.extend scope,
    marketdata_columns: fetch
