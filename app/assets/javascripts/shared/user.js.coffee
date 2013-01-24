##= require jquery
##= require mx.i18n


root            = @
root.shared    ?= {}
scope           = root.shared


fetch = ->
    deferred = new $.Deferred
    
    result = {}
    
    $.ajax
        url: "http://www.beta.micex.ru/cu"
        dataType: 'json'
        xhrFields:
            withCredentials: true
    .done (json) ->
        result.data     = json
        result.error    = false
    .fail (xhr, error) ->
        result.error    = true
    .always ->
        deferred.resolve(result)
    
    deferred.promise
        result: result



full_name = (data) ->


full_name_or_nickname = (data) ->



widget = (container) ->
    
    container = $(container) ; return if container.length == 0

    user = fetch()
    
    user.then ->
        user = user.result


$.extend scope,
    user: widget
