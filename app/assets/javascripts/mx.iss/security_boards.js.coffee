root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (ticker, options = {}) ->
    deferred = new $.Deferred
    
    data = []
    
    $.ajax
        url: "#{scope.url_prefix}/securities/#{ticker}/boards.json"
        data:
            is_trading: if options.is_traded then options.is_traded else ''
            'iss.meta': 'off'
            'iss.only': 'boards'
        dataType: 'json'
    .then (json) ->
        data.push(scope.merge_columns_and_data(json?.boards)...)
        deferred.resolve(data)
    
    deferred.promise({ data: data })


$.extend scope,
    security_boards: fetch
