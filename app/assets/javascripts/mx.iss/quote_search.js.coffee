root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (query, options = {}) ->
    deferred = new $.Deferred
    
    data = []
    
    options.group_by    ||= ''
    options.is_traded   ||= ''
    
    xhr = $.ajax
        url: "#{scope.url_prefix}/securities.json"
        data:
            q:              query
            group_by:       options.group_by
            is_trading:     options.is_traded
            'iss.meta':     'off'
            'iss.only':     'securities'
        dataType: 'json'
    .done (json) ->
        data.push(scope.merge_columns_and_data(json?.securities)...)
        deferred.resolve(data)
    
    deferred.promise 
        data:   data
        xhr:    xhr
        query:  query


$.extend scope,
    quote_search: fetch
