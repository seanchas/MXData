root    = @
scope   = root['mx']['data']


$       = jQuery


search_param_threshold = 3
search_keypress_timeout = 300


widget = (element, options = {}) ->
    element = $(element); return unless _.size(element) > 0

    search_param        = undefined
    keypress_timeout    = undefined
    
    render_instruments = (data) ->
        list = make_instruments_list(element)
        list.html("")
        for item in data
            list.append $("<dt>").html(item.secid)
            list.append $("<dd>").html(item.name)
    
    search = (param) ->
        return if param == search_param
        search_param = param
        mx.iss.quote_search(param).then render_instruments
    
    observe_keyboard = (event) ->
        param = element.val()
        return unless param? and param.length >= search_param_threshold
        clearTimeout keypress_timeout
        keypress_timeout = _.delay search, search_keypress_timeout, param
        

    element.on "keyup", observe_keyboard

    {}


make_instruments_list = _.once (element) ->
    list = $("<dl>").addClass("security-list")
    element.after(list)
    list


$.extend scope,
    quote_search: widget
