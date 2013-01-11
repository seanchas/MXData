root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (securities, marketdata) ->
    securities = _.reduce securities, ((memo, record) -> memo["#{record.BOARDID}/#{record.SECID}"] = record; memo), {}
    marketdata = _.reduce marketdata, ((memo, record) -> memo["#{record.BOARDID}/#{record.SECID}"] = record; memo), {}
    _.reduce _.keys(securities), ((memo, key) -> memo.push _.extend(securities[key], marketdata[key]); memo), []



fetch2 = (engine, market, params, options = {}) ->
    deferred = new $.Deferred
    
    data = {}
    
    options.only ||= 'securities,marketdata'
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities.json"
        data:
            'iss.meta':     'off'
            'iss.only':     [options.only, 'dataversion'].join(',')
            'securities':   params.join(',')
        dataType: 'json'
        xhrFields:
            withCredentials: true
    .then (json, status, xhr) ->
        for key, value of json
            if _.isObject(value) and value.columns? and value.data?
                value = scope.merge_columns_and_data(value)
            data[key] = value
        
        data['x-marker'] = xhr.getResponseHeader('X-MicexPassport-Marker')

        deferred.resolve(data)        
    
    deferred.promise({ data: data })



fetch = (engine, market, params, options = {}) ->
    deferred = new $.Deferred

    data = []
    
    options.only ||= 'securities,marketdata'
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities.json"
        data:
            'iss.meta':     'off'
            'iss.only':     'securities,marketdata'
            'securities':   params.join(',')
        dataType: 'json'
    .then (json, status, xhr) ->
        data.push(prepare(scope.merge_columns_and_data(json?.securities), scope.merge_columns_and_data(json?.marketdata))...)
        
        deferred.resolve(data)

    deferred.promise({ data: data })


$.extend scope,
    marketdata: fetch2
    marketdata2: fetch2
