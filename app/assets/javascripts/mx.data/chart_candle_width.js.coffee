root    = @
scope   = root['mx']['data']


$       = jQuery


cache = kizzy('data.chart.period')


data            = undefined
candle_widths   = []

default_candle_width_interval = 1


make_candle_widths_view = (wrapper) ->
    container = $('<ul>')
        .attr({ id: 'chart_candle_width' })

    for candle_width in candle_widths
        container.append $('<li>')
            .attr( { 'data-interval': candle_width.interval, 'data-duration': candle_width.duration })
            .html(candle_width.title)

    wrapper.append container

    container



widget = (wrapper) ->
    wrapper                 = $(wrapper); return if _.size(wrapper) == 0
    
    current_candle_width    = undefined
    deferred                = new $.Deferred

    candle_widths_view      = undefined
    
    data                   ?= mx.iss.metadata()
    
    ready_for_render        = $.when data
    
    candle_width_changed    = true
    
    
    # broadcast period
    
    
    broadcast = ->
        return unless deferred.state() == 'resolved'

        return unless candle_width_changed
        
        candle_width_changed = false
    
        $(window).trigger 'chart:candle_width:changed', current_candle_width
    
    # type
    
    set_cached_candle_width = ->
        set_candle_width_by_interval(cache.get('candle_width')?.interval ? default_candle_width_interval)
        
    set_candle_width_by_interval = (interval) ->
        return if current_candle_width?.interval == interval
        
        current_candle_width = _.first(candle_width for candle_width in candle_widths when candle_width.interval == interval)
        
        $('li', candle_widths_view).removeClass('selected');
        $("li[data-interval=#{current_candle_width.interval}]", candle_widths_view).addClass('selected');
        
        cache.set('candle_width', current_candle_width)
        
        candle_width_changed = true
        
        broadcast()


    # render periods
    
    ready_for_render.then ->
        candle_widths       = data.durations
        
        candle_widths_view  = make_candle_widths_view wrapper
    
        candle_widths_view.on 'click', 'li', (event) ->
            set_candle_width_by_interval $(@).data('interval')

        set_cached_candle_width()
        
        deferred.resolve()
    

    deferred.promise({ data: -> current_candle_width })
    


$.extend scope,
    chart_candle_width: widget
