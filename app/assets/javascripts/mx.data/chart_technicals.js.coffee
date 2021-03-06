root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.chart.technicals')


max_technicals              = 10
max_identical_technicals    = 3


technicals_descriptors      = undefined

technicals_descriptors_hash = _.once ->
    _.reduce technicals_descriptors, (memo, technical_descriptor) ->
        memo[technical_descriptor.id] = technical_descriptor ; memo
    , {}



locales =
    ru:
        add_technical: 'Добавить индикатор'
        remove_technical: 'Удалить'
    en:
        add_technical: 'Add technical'
        remove_technical: 'Remove'



serialize_view = (view) ->
    $('input,select', view).serializeArray()




make_anchors_view = (wrapper) ->
    $('<ul>')
        .addClass('anchors clearfix')
        .appendTo(wrapper)


make_factory_anchor_view = (wrapper) ->
    $('<li>')
        .addClass('anchor factory')
        .html($('<span>').html(locales[mx.I18n.locale].add_technical))
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

    wrapper.append $('<li>').html('<table><thead></thead><tbody></tbody></table>')
    thead = $('thead', wrapper)
    tbody = $('tbody', wrapper)
    
    thead.append $('<tr>').append($('<td>').attr('colspan', 3).html(descriptor.description))

    unless _.isEmpty(descriptor.params)
        
        for param, index in descriptor.params
            row = $('<tr>').appendTo tbody
            row.append $('<th>').html(param.title)
            row.append $('<td>').addClass('value').append make_input_view(param, values[index]?.value)
            row.append $('<td>').addClass('hint').html(param.description)

    # remove button
    wrapper.append $('<li>').addClass('remove').html($('<span>').html(locales[mx.I18n.locale].remove_technical))

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
    
    technicals_descriptors ?= mx.cs.technicals()

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

        update_technicals_values()

        cache.set "technicals", technicals
        
        broadcast()
    
    update_technicals_values = ->
        technicals_views = $('li.technical', wrapper)
        for technical, index in technicals
            view = $('span', technicals_views.eq(index))
            view.html("#{technicals_descriptors_hash()[technical.id].title} (#{_.pluck(technical.values, 'value').join(', ')})") unless _.isEmpty(technical.values)
            
    
    colorize = (colors_indices) ->
        technicals_views = $('li.technical', wrapper)
        for color_index, index in colors_indices
            $('span', technicals_views[index]).css('background-color', scope.background_colors[color_index])
    

    # render technicals
    
    ready_for_render.then ->
        anchors_view        = make_anchors_view wrapper
        factory_anchor_view = make_factory_anchor_view anchors_view
        
        make_factory_child_view factory_anchor_view
        
        add_cached_technicals()
        update_technicals_values()
        
        anchors_view.on 'click', '.anchor', -> toggle_child_view_for_anchor $ @
        
        wrapper.on 'click', 'ul.factory li', -> add_technical $(@).data('id') ; update_technicals_values()
        
        wrapper.on 'click', 'ul.technical li.remove', -> anchor = $(@).closest('.child').data('anchor') ; remove_technical_at $('.anchor', anchors_view).index(anchor)
        
        wrapper.on 'change', 'input, select', serialize
        
        $(window).on 'chart:indicators:colors', (event, colors_indices) -> colorize colors_indices
        
        deferred.resolve()
    
    # return
    
    deferred.promise
        data: -> technicals
        meta: -> technicals_descriptors
        
        

$.extend scope,
    chart_technicals: widget
