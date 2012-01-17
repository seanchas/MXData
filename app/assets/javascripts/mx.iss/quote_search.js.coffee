root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (query, options = {}) ->
    deferred = new $.Deferred
    
    $.ajax
        url: "#{scope.url_prefix}/securities.jsonp?callback=?"
        data:
            q:          query
            'iss.meta': 'off'
            'iss.only': 'securities'
        dataType: 'jsonp'
    .then (json) ->
        deferred.resolve scope.merge_columns_and_data json?.securities
    
    deferred.promise()


$.extend scope,
    quote_search: fetch
