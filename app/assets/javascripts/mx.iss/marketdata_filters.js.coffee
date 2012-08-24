root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (data) ->
    _.reduce data, ((memo, item) -> (memo[item.filter_name] ||= []).push(item); memo), {}


fetch = (engine, market) ->
    deferred = new $.Deferred
    
    data = {}
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities/columns/filters.jsonp?callback=?"
        data:
            'iss.meta': 'off'
            'iss.only': 'filters'
        dataType: 'jsonp'
    .then (json) ->
        for key, value of prepare(scope.merge_columns_and_data json?.filters)
            data[key] = value
        
        deferred.resolve(data)
    
    deferred.promise({ data: data })
    

$.extend scope,
    marketdata_filters: fetch
