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
    technicals2: -> scope.fetch 'chart_technicals', arguments...


$.extend scope.fetch_descriptors,
    chart_technicals:
        url: ->
            "/indicators.hs"
        parse: (json) ->
            json
