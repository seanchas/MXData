root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (securities, marketdata) ->
    securities = _.reduce securities, ((memo, record) -> memo["#{record.BOARDID}/#{record.SECID}"] = record; memo), {}
    marketdata = _.reduce marketdata, ((memo, record) -> memo["#{record.BOARDID}/#{record.SECID}"] = record; memo), {}
    _.reduce _.keys(securities), ((memo, key) -> memo.push _.extend(securities[key], marketdata[key]); memo), []


fetch = (engine, market, params) ->
    deferred = new $.Deferred

    data = []
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities.jsonp?callback=?"
        data:
            'iss.meta':     'off'
            'iss.only':     'securities,marketdata'
            'securities':   params.join(',')
        dataType: 'jsonp'
    .then (json) ->
        deferred.resolve prepare scope.merge_columns_and_data(json?.securities), scope.merge_columns_and_data(json?.marketdata)

    deferred.promise()


$.extend scope,
    marketdata: fetch
