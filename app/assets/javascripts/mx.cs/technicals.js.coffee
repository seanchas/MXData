root    = @
scope   = root['mx']['cs']

$       = jQuery


fetch = ->
    deferred = new $.Deferred
    
    data = []
    
    $.ajax
        url: "#{scope.url_prefix}/indicators.hs?callback=?"
        dataType: 'jsonp'
    .then (json) ->
        data.push json...
        deferred.resolve data
    
    deferred.promise(data)


$.extend scope,
    technicals: fetch
