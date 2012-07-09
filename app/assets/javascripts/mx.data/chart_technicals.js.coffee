root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.chart.technicals')


max_technicals              = 10
max_identical_technicals    = 3


technicals_descriptors  = mx.cs.technicals()




make_anchors_view = (wrapper) ->
    $('<ul>')
        .addClass('anchors clearfix')
        .appendTo(wrapper)


make_factory_anchor_view = (wrapper) ->
    $('<li>')
        .addClass('anchor factory')
        .html($('<span>').html('Новый индикатор'))
        .appendTo(wrapper)


make_factory_child_view = (anchor) ->
    view    = $('<li>')
        .addClass('child')

    wrapper = $('<ul>')
        .addClass('factory clearfix')
        .appendTo(view)
    
    for descriptor in technicals_descriptors
        wrapper.append $('<li>')
            .data('id', descriptor.id)
            .html($('<span>').html(descriptor.title))
    
    anchor.data('child', view)
    
    view
        .data('anchor', anchor)
        .insertAfter(anchor)
    
    view.hide()


make_technical_anchor_view = (wrapper, id, values) ->
    descriptor = _.first(descriptor for descriptor in technicals_descriptors when descriptor.id == id) ; return unless descriptor?
    
    view = $('<li>')
        .addClass('anchor technical')
        .html($('<span>').html(descriptor.title))
        .insertBefore($('.anchor', wrapper).last())
    
    make_technical_child_view view
    
    view


make_technical_child_view = (anchor) ->
    view = $('<li>')
        .addClass('child')
    
    wrapper = $('<ul>')
        .addClass('technical clearfix')
        .appendTo(view)
    
    wrapper.append $('<li>').addClass('remove').html($('<span>').html('Удалить'))

    view.insertAfter(anchor.siblings('.anchor').last())
    
    anchor.data('child', view)
    view.data('anchor', anchor)
    
    view.hide()


###

make_technicals_factory_controller = (wrapper) ->
    $('<div>')
        .addClass('factory_controller anchor')
        .append($('<span>').html('Новый индикатор'))
        .appendTo(wrapper)
    


make_technicals_factory_view = (controller) ->
    view = $('<ul>')
        .addClass('factory view')
    
    for descriptor in technicals_descriptors
        $('<li>')
            .addClass('technical')
            .data('id', descriptor.id)
            .html(descriptor.title)
            .appendTo(view)
    
    view
        .hide()
        .insertAfter(controller)


make_technical_view = (controller, id, values = []) ->
    descriptor = _.first(descriptor for descriptor in technicals_descriptors when descriptor.id == id) ; return unless descriptor?
    
    view = $('<div>')
        .addClass('technical anchor')
        .data('id', id)
        .html(descriptor.title)
        .css('background-color', scope.background_colors[0])
        .insertBefore(controller)
    
    make_technical_params_view view
    
    view


make_technical_params_view = (technical, values = []) ->
    descriptor = _.first(descriptor for descriptor in technicals_descriptors when descriptor.id == technical.data('id')) ; return unless descriptor?
    
    view = $('<div>')
        .addClass('technical_params view')
        .data('anchor', technical)
        .hide()
    
    view.append $('<div>').data('id', descriptor.id).addClass('remove').html($('<span>').html('Удалить'))
    
    technical.data('view', view)
###    

widget = (wrapper, options = {}) ->
    wrapper                 = $(wrapper); return if _.size(wrapper) == 0

    technicals              = []
    deferred                = new $.Deferred

    anchors_view            = null
    
    ready_for_render        = $.when technicals_descriptors
    
    technicals_changed      = true
    

    # broadcast technicals
    
    broadcast = ->
        return unless deferred.state() == 'resolved'

        return unless technicals_changed
        
        technicals_changed = false
    
        $(window).trigger 'chart:technicals:changed', [technicals]
        
    # technicals
    
    add_cached_technicals = ->
        cached_technicals = cache.get "technicals" ; return unless cached_technicals? ; add_technical technical.id, technical.values for technical in cached_technicals
        
    
    add_technical = (id, values = []) ->
        return if _.size(technicals) >= max_technicals
        return if _.size(technical for technical in technicals when technical.id == id) >= max_identical_technicals
        
        view = make_technical_anchor_view anchors_view, id, values
        technicals.push { id: id, values: serialize_technical_view view }
        
        technicals_changed = true
        cache.set "technicals", technicals
        
        broadcast()
    
    remove_technical_at = (index) ->
        
        console.log index
        
        technicals = _.without technicals, technicals[index]
        remove_technical_view $('.anchor', wrapper).eq(index)

        technicals_changed = true
        cache.set "technicals", technicals
        
        broadcast()
    
    remove_technical_view = (anchor) ->
        view = anchor.data('child')
        hide_child_view view, -> anchor.remove() ; view.remove()


    toggle_child_view_for_anchor = (anchor) ->
        child = $ anchor.data('child') ; return if _.size(child) == 0
        if child.is(':visible') then hide_child_view(child) else show_child_view(child)

    show_child_view = (view, callback) ->
        view = $ view
        
        hide_child_view(v) for v in view.siblings('.child').not(view) when $(v).is(':visible')
        
        view.data('anchor').addClass('active') if view.data('anchor')?
        view.show('blind', {}, 'fast', callback) if view.is(':hidden')

    hide_child_view = (view, callback) ->
        view = $ view
        view.data('anchor').removeClass('active') if view.data('anchor')?
        view.hide( 'blind', {}, 'fast', callback) if view.is(':visible')
            
        # utilities
    
    serialize_technical_view = (view) ->
        $('input,select', view).serializeArray()
    

    serialize = ->
        technicals_views = $('li.technical', technicals_list)

        for technical, index in technicals
            technical.values = serialize_technical_view technicals_views[index]

        technicals_changed = true
        cache.set "technicals", technicals
        
        broadcast()
    

    # render technicals
    
    ready_for_render.then ->
        anchors_view        = make_anchors_view wrapper
        factory_anchor_view = make_factory_anchor_view anchors_view
        
        make_factory_child_view factory_anchor_view
        
        add_cached_technicals()
        
        anchors_view.on 'click', '.anchor', -> toggle_child_view_for_anchor $ @
        
        wrapper.on 'click', 'ul.factory li', -> add_technical $(@).data('id')
        
        wrapper.on 'click', 'ul.technical li.remove', -> anchor = $(@).closest('.child').data('anchor') ; remove_technical_at $('.anchor', anchors_view).index(anchor)
        
        deferred.resolve()
    
    # return
    
    deferred.promise
        data: -> technicals
        meta: -> technicals_descriptors
        
        

$.extend scope,
    chart_technicals: widget
