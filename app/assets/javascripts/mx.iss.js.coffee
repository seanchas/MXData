##= require jquery
##= require underscore
##= require mx.locale
##= require_self
##= require_tree ./mx.iss

root = @

root['mx'] ?= {}
root['mx']['iss'] = {}


scope = root['mx']['iss']


requests_cache = {}


merge = (json) ->
    return [] unless json.data? and json.columns?
    for datum in json.data
        item = {}
        for column, index in json.columns
            item[column] = datum[index]
        item
    

fetch = (name, args...) ->
    descriptor = scope.fetch_descriptors[name] ; return undefined unless descriptor?
    
    options         = _.last(args) ; options = {} unless _.isObject(options) and !_.isArray(options)
    cache_key       = JSON.stringify([name, (descriptor.cache_key ? _.identity)(args...), mx.locale()])
    cached_request  = requests_cache[cache_key]

    if cached_request?
        return cached_request if      cached_request == 'pending'
        return cached_request unless  options.force == true
    
    cached_request = new $.Deferred
    
    result = {}
    
    $.ajax
        url: scope.url_prefix + descriptor.url(args...)
        data: $.extend(descriptor.xhr_data(args...), { 'iss.meta': 'off', 'lang': mx.locale() })
        cache: false
        dataType: 'json'
        xhrFields:
            withCredentials: true

    .done (json, status, xhr) ->
        result.data         = descriptor.parse(json, args)

    .fail (xhr, status, error) ->
        result.error        = error
    
    .always (data_or_xhr, status, xhr_or_error) ->
        xhr                 = if status == 'success' then xhr_or_error else data_or_xhr
        result['x-marker']  = xhr.getResponseHeader('X-MicexPassport-Marker')
        cached_request.resolve(result)
    
    requests_cache[cache_key] = cached_request.promise({ result: result })


$.extend scope,
    url_prefix:             'http://www.beta.micex.ru/iss'
    fetch:                  fetch
    fetch_descriptors:      {}
    merge_columns_and_data: merge
