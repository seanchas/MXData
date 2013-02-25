root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (securities, marketdata) ->
    securities = _.reduce securities, ((memo, record) -> memo[record.id] = record; memo), {}
    marketdata = _.reduce marketdata, ((memo, record) -> memo[record.id] = record; memo), {}
    _.extend securities, marketdata


fetch = (engine, market) ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities/columns.jsonp?callback=?"
        data:
            'iss.meta': 'off'
            'iss.only': 'securities,marketdata'
        dataType: 'jsonp'
    .then (json) ->
        for key, value of prepare(scope.merge_columns_and_data(json?.securities), scope.merge_columns_and_data(json?.marketdata))
            data[key] = value

        deferred.resolve(data)
    
    deferred.promise({ data: data })


$.extend scope,
    __marketdata_columns: fetch
