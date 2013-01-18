root    = @
scope   = root['mx']['iss']
$       = jQuery


fetch = ->
    scope.fetch 'security_types', arguments...


$.extend scope,
    security_types: fetch

$.extend scope.fetch_descriptors,
    security_types:
        cache_key: ->
            ""
        url: ->
            "/securitytypes.jsonp"
        xhr_data: ->
            'iss.only': 'securitytypes'
        parse: (json) ->
            scope.merge_columns_and_data(json?.securitytypes)
