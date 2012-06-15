root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.chart.technicals')


max_technicals              = 5
max_identical_technicals    = 3


technicals_descriptors  = mx.cs.technicals()



make_technicals_factory = (wrapper) ->
    list = $('<select>')
    
    list.append $('<option>').html('Добавить')
    
    for descriptor in technicals_descriptors
        list.append $('<option>')
            .attr('value', descriptor.id)
            .html(descriptor.title)
    
    wrapper.append list
    
    list.wrap $('<div>').addClass('factory')
    
    list



make_technical = (wrapper, id, values = []) ->
    descriptor = _.first(descriptor for descriptor in technicals_descriptors when descriptor.id == id) ; return unless descriptor?
    
    view = $('<li>').addClass('technical').html(descriptor.title)
    view.append $('<a>').addClass('remove').attr('href', '#').html('-')
    
    if descriptor.params and _.size(descriptor.params) > 0
        params_view = $('<ul>')

        for param in descriptor.params

            param_view          = $('<li>').html(param.title)
            param_value_view    = switch param.value_type
                when 'select'
                    make_select_from_param param
                else
                    make_text_input_from_param param
            
            param_view.append   param_value_view
            params_view.append  param_view

        view.append params_view
    
    wrapper.append view



make_select_from_param = (param) ->
    view = $('<select>')
    
    for item in eval(param.value)
        view.append $('<option>').attr('id', item.id).html(item.title)
    
    view



make_text_input_from_param = (param) ->
    view = $('<input>')
        .attr({ type: 'text', name: param.id })
        .val(param.value)
    
    view



widget = (wrapper, options = {}) ->
    wrapper                 = $(wrapper); return if _.size(wrapper) == 0

    technicals              = []
    deferred                = new $.Deferred


    technicals_factory      = null
    technicals_list         = $ 'ul.list', wrapper

    
    ready_for_render        = $.when technicals_descriptors
    
    technicals_changed      = false
    

    # broadcast technicals
    
    broadcast = ->
        return unless deferred.state() == 'resolved'

        return unless technicals_changed
        
        technicals_changed = false
    
        if options.callback and _.isFunction(options.callback)
            options.callback(technicals)
        
    # technicals
    
    add_cached_technicals = ->
        cached_technicals = cache.get "technicals" ; return unless cached_technicals? ; add_technical technical.id, technical.values for technical in cached_technicals
        
    
    add_technical = (id, values = []) ->
        technicals.push { id: id, values: values }
        make_technical technicals_list, id, values
        
        technicals_changed = true
        cache.set "technicals", technicals
        
        broadcast()
    
    remove_technical_at = (index) ->
        technicals = _.without technicals, technicals[index]
        $('li.technical', technicals_list).eq(index).remove()

        technicals_changed = true
        cache.set "technicals", technicals
        
        broadcast()

    # render technicals
    
    ready_for_render.then ->
        technicals_factory = make_technicals_factory wrapper
        
        technicals_factory.on 'change', (event) ->
            add_technical technicals_factory.val() ; technicals_factory.blur().val(0)
        
        technicals_list.on 'click', 'a.remove', (event) ->
            event.preventDefault() ; remove_technical_at $('li.technical', technicals_list).index $(@).closest('li')
        
        add_cached_technicals()

        deferred.resolve()
    
    # return
    
    deferred.promise({ technicals: -> technicals })
        
        

$.extend scope,
    chart_technicals: widget
