@mx            ?= {}

requests_cache  = {}


fetch = (scope, name, args...) ->
    descriptor = scope.fetch_descriptors[name] ; return undefined unless descriptor?
    
    options         = _.last(args) ; options = {} unless _.isObject(options) and !_.isArray(options)
    cache_key       = JSON.stringify([name, (descriptor.cache_key ? _.identity)(args...), mx.locale()])
    cached_request  = requests_cache[cache_key]
    
    now             = + new Date
    expires_at      = if options.expires_in? then now + options.expires_in
    
    if cached_request?
        return cached_request if        cached_request.state() == 'pending'
        return cached_request if        cached_request.expires_at? and expires_at? and cached_request.expires_at > now
        return cached_request unless    options.force == true
    
    cached_request = new $.Deferred
    
    result = {}
    
    $.ajax
        url: scope.url_prefix + descriptor.url(args...)
        data: $.extend(descriptor.xhr_data?(args...) ? {}, { 'iss.meta': 'off', 'lang': mx.I18n.locale })
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
    
    requests_cache[cache_key] = cached_request.promise({ result: result, expires_at: expires_at })


$.extend @mx,
    url:    'http://www.beta.micex.ru'
    fetch:  fetch
