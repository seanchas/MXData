root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.chart.technicals')


max_technicals              = 10
max_identical_technicals    = 3


technicals_descriptors  = mx.cs.technicals()



serialize_view = (view) ->
    $('input,select', view).serializeArray()




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
    
    make_technical_child_view view, descriptor, values
    
    view


make_technical_child_view = (anchor, descriptor, values) ->
    view = $('<li>')
        .addClass('child')
    
    wrapper = $('<ul>')
        .addClass('technical clearfix')
        .appendTo(view)

    unless _.isEmpty(descriptor.params)
        wrapper.append $('<li>').html('<table><thead></thead><tbody></tbody></table>')
        thead = $('thead', wrapper)
        tbody = $('tbody', wrapper)
        
        thead.append $('<tr>').append($('<td>').attr('colspan', 3).html('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'))
        
        for param in descriptor.params
            row = $('<tr>').appendTo tbody
            row.append $('<th>').html(param.title)
            row.append $('<td>').addClass('value').append make_input_view(param, values[param.id])
            row.append $('<td>').addClass('hint').html('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.')

    # remove button
    wrapper.append $('<li>').addClass('remove').html($('<span>').html('Удалить'))

    view.insertAfter(anchor.siblings('.anchor').last())
    
    anchor.data('child', view)
    view.data('anchor', anchor)
    
    view.hide()



make_input_view = (param, value) ->
    switch param.value_type
        when 'integer', 'float'
            make_text_input_view param, value
        when 'select'
            make_select_view param, value

make_text_input_view = (param, value) ->
    $('<input>')
        .attr({ type: 'text', name: param.id })
        .val(value ? param.value)

make_select_view = (param, value) ->
    select = $('<select>').attr('name', param.id)
    
    for item in eval(param.value_range)
        select.append $('<option>').attr('value', item.id).html(item.title)

    select.val(value ? param.value)


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
        $('input,select', $(view).data('child')).serializeArray()
    

    serialize = ->
        technicals_views = $('li.technical', wrapper)

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
        
        wrapper.on 'change', 'input, select', serialize
        
        deferred.resolve()
    
    # return
    
    deferred.promise
        data: -> technicals
        meta: -> technicals_descriptors
        
        

$.extend scope,
    chart_technicals: widget
