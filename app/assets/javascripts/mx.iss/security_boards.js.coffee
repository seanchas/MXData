root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (ticker, options = {}) ->
    deferred = new $.Deferred
    
    $.ajax
        url: "#{scope.url_prefix}/securities/#{ticker}/boards.jsonp?callback=?"
        data:
            is_trading: if options.is_traded then options.is_traded else ''
            'iss.meta': 'off'
            'iss.only': 'boards'
        dataType: 'jsonp'
    .then (json) ->
        deferred.resolve scope.merge_columns_and_data json?.boards
    
    deferred.promise()


$.extend scope,
    security_boards: fetch
