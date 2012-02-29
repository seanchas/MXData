root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = (ticker) ->
    deferred = new $.Deferred
    
    $.ajax
        url: "#{scope.url_prefix}/securitygroups.jsonp?callback=?"
        data:
            'iss.meta': 'off'
            'iss.only': 'securitygroups'
        dataType: 'jsonp'
    .then (json) ->
        deferred.resolve scope.merge_columns_and_data json?.securitygroups
    
    deferred.promise()


$.extend scope,
    security_groups: fetch
