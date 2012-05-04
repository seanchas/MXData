root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (ticker) ->
    deferred = new $.Deferred
    
    data = []
    
    $.ajax
        url: "#{scope.url_prefix}/securitygroups.jsonp?callback=?"
        data:
            'iss.meta': 'off'
            'iss.only': 'securitygroups'
        dataType: 'jsonp'
    .then (json) ->
        data.push(scope.merge_columns_and_data(json?.securitygroups)...)
        deferred.resolve data
    
    deferred.promise(data)


$.extend scope,
    security_groups: fetch
