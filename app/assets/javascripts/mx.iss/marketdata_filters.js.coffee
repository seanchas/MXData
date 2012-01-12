root    = @
scope   = root['mx']['iss']
$       = jQuery


prepare = (data) ->
    _.reduce data, (memo, item) ->
        (memo[item.filter_name] ||= []).push(item)
        memo
    , {}


fetch = (param) ->
    deferred = new $.Deferred
    
    [engine, market] = param.split(":")
    
    $.ajax
        url: "#{scope.url_prefix}/engines/#{engine}/markets/#{market}/securities/columns/filters.jsonp?callback=?"
        data:
            'iss.meta': 'off'
            'iss.only': 'filters'
        dataType: 'jsonp'
    .then (json) ->
        deferred.resolve prepare scope.merge_columns_and_data json?.filters
    
    deferred.promise()
    

$.extend scope,
    marketdata_filters: fetch
