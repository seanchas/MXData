root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.chart.type')



data = [
    { id: 'candles',    title: 'Свечи' }
    { id: 'stockbar',   title: 'Бары' }
    { id: 'line',       title: 'Линия' }
]


default_type = 'candles'


make_types_view = (wrapper) ->
    container = $('<ul>')
        .attr({ id: 'chart_types' })

    for item in data
        container.append $('<li>')
            .attr('data-type', item.id)
            .html(item.title)

    wrapper.append container

    container


widget = (wrapper) ->
    wrapper             = $(wrapper); return if _.size(wrapper) == 0
    
    current_type        = undefined
    deferred            = new $.Deferred

    types_view          = undefined
    
    ready_for_render    = $.when(true)
    
    type_changed        = true


    # broadcast type
    
    
    broadcast = ->
        return unless deferred.state() == 'resolved'

        return unless type_changed
        
        type_changed = false
    
        $(window).trigger 'chart:type:changed', current_type

    
    # type
    
    set_cached_type = ->
        set_type(cache.get('type') ? default_type)
        
    set_type = (type) ->
        return if current_type == type
        
        current_type = type
        
        $('li', types_view).removeClass('selected');
        $("li[data-type=#{current_type}]", types_view).addClass('selected');
        
        cache.set('type', current_type)
        
        type_changed = true
        
        broadcast()
    
    # render types
    
    ready_for_render.then ->
        types       = data
        types_view  = make_types_view wrapper, types
        
        types_view.on 'click', 'li', (event) ->
            set_type $(@).data('type')
        
        set_cached_type()
        
        deferred.resolve()
        
        
        
    deferred.promise({ data: -> current_type })


$.extend scope,
    chart_type: widget
