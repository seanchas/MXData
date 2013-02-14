root    = @
scope   = root['mx']['data']


$       = jQuery

cache = kizzy('data.chart')


fetch_chart_type = 'candles'


refresh_delay    = 5 * 1000


cs_to_hs_types =
    line:       'line'
    candles:    'candlestick'
    stockbar:   'ohlc'
    bar:        'column'



candles_yAxis_margin = 30
candles_yAxis_height = 250

volumes_yAxis_margin = 30
volumes_yAxis_height = 100

default_xAxis_margin = 30
default_xAxis_height = 25

navigator_height = 50
scrollbar_height = 15


default_chart_options =
    chart:
        alignTicks: true
        spacingTop: 1
        spacingLeft: 1
        spacingRight: 1
        spacingBottom: 1
    
    credits:
        enabled: false
    
    rangeSelector:
        enabled: false
    
    navigator:
        height: 50
    
    scrollbar:
        height: 15
    
    tooltip:
        crosshairs: true
    
    plotOptions:
        ohlc:
            lineWidth: 2
        scatter:
            marker:
                radius: 2
                symbol: 'circle'
        series:
            gapSize: 60
            dataGrouping:
                enabled: false


default_candles_series_options =
    dataGrouping:
        smoothed: true


default_candles_yAxis_options = 
    lineWidth:  1
    height:     candles_yAxis_height
    top:        candles_yAxis_margin
    offset:     0
    showEmpty:  false


default_volumes_series_options =
    dataGrouping:
        smoothed: true


default_volumes_yAxis_options =
    lineWidth:  1
    height:     volumes_yAxis_height
    top:        candles_yAxis_margin + candles_yAxis_height + volumes_yAxis_margin
    offset:     0
    opposite: true
    showEmpty:  false
    alignTicks: false


default_xAxis_options =
    top:    0
    offset: 0

no_data = ->
    $('<div>').addClass('no_data').html('Нет данных')


validate_instruments = (instruments, data_sources) ->
    for instrument in instruments
        data_source         = data_sources[instrument.id]
        instrument.failure  = data_source.error_message if data_source.error_message?
        instrument.disabled = true if instrument.failure?
    instruments


create_candles = (data_sources, instruments, chart_type) ->
    
    series  = []
    yAxis   = []

    effective_instruments_size  = _.size(instrument for instrument in instruments when !instrument.disabled)
    effective_index             = 0
    
    for instrument, index in instruments
        continue if instrument.disabled == true
        
        effective_chart_type = if effective_index > 0 or effective_instruments_size > 2 then 'line' else chart_type

        candles         = _.first data_sources[instrument.id].candles
        candles_data    = candles["#{if effective_chart_type == 'line' then 'line' else 'candles'}_data"]
        
        candles_serie_options = $.extend true, {}, default_candles_series_options,
            id:     "candles:#{index}"
            name:   instrument.title || instrument.id
            color:  scope.colors[index]
            type:   cs_to_hs_types[effective_chart_type]
            data:   candles_data
            yAxis:  if effective_instruments_size == 2 and effective_index == 1 then 1 else 0
        
        if effective_instruments_size > 2
            $.extend candles_serie_options,
                compare: 'percent'

        series.push candles_serie_options
        
        effective_index++
    
    
    yAxis.push $.extend true, {}, default_candles_yAxis_options,
        opposite:       true
    
    yAxis.push $.extend true, {}, default_candles_yAxis_options
    
    
    if (effective_instruments_size <= 2)
        $.extend yAxis[0],
            labels:
                style:
                    color: series[0].color

    if (effective_instruments_size == 2)
        $.extend yAxis[1],
            labels:
                style:
                    color: series[1].color

    
    series:     series
    yAxis:      yAxis
    offset:     candles_yAxis_margin + candles_yAxis_height


update_candles = (data_sources, instruments, chart_type, offset, options) ->

    effective_instruments_size  = _.size(instrument for instrument in instruments when !instrument.disabled)
    effective_index             = 0
    
    for instrument, index in instruments
        continue if instrument.disabled == true
        
        effective_chart_type = if effective_index > 0 or effective_instruments_size > 2 then 'line' else chart_type

        candles         = _.first data_sources[instrument.id].candles
        candles_data    = candles["#{if effective_chart_type == 'line' then 'line' else 'candles'}_data"]
        
        options.chart.series[effective_index + offset].setData(candles_data, false)
        
        effective_index++
    
    effective_index


create_volumes = (data_sources, instruments) ->

    series  = []
    yAxis   = []
    
    yAxis.push $.extend true, {}, default_volumes_yAxis_options

    effective_instruments_size  = _.size(instrument for instrument in instruments when !instrument.disabled)
    effective_index             = 0
    
    for instrument, index in instruments
        break if effective_instruments_size > 2 and effective_index > 0
        break if effective_index > 1

        continue if instrument.disabled == true
    
        volumes = _.first data_sources[instrument.id].volumes
        
        volumes_serie_options = $.extend true, {}, default_volumes_series_options,
            id:     "volumes:#{index}"
            name:   instrument.title || instrument.id
            color:  scope.colors[index]
            type:   cs_to_hs_types[volumes.type]
            data:   volumes.data
            yAxis:  2
        
        series.push volumes_serie_options

        effective_index++
        
    
    series:     series
    yAxis:      yAxis
    offset:     volumes_yAxis_margin + volumes_yAxis_height


update_volumes = (data_sources, instruments, offset, options) ->
    effective_instruments_size  = _.size(instrument for instrument in instruments when !instrument.disabled)
    effective_index             = 0
    
    for instrument in instruments
        break if effective_instruments_size > 2 and effective_index > 0
        break if effective_index > 1

        continue if instrument.disabled == true
        
        volumes         = _.first data_sources[instrument.id].volumes
        volumes_data    = volumes.data
        
        options.chart.series[effective_index + offset].setData(volumes_data, false)
        
        effective_index++
    
    effective_index


create_inline_technicals = (data_sources, instruments, technicals, offset, options) ->
    series  = []
    yAxis   = []
    
    total                   = _.size instruments
    effective_instruments   = (instrument for instrument in instruments when !instrument.disabled)
    technical_index         = 0

    if _.size(effective_instruments) < 3
        
        effective_instrument    = _.first effective_instruments
        data_source             = data_sources[effective_instrument.id].technicals
        
        for technical, index in data_source
            
            continue unless !!technical.inline
            
            for serie in technical.data
                serie_options = $.extend true, {}, default_candles_series_options,
                    id:     "inline technicals:#{technical_index}"
                    name:   options.technicals_meta[technicals[index].id].title
                    color:  scope.colors[total + technical_index]
                    type:   cs_to_hs_types[technical.type]
                    data:   serie
                    yAxis:  0
                
                if technicals[index].id == 'psar'
                    serie_options = $.extend serie_options,
                        lineWidth: 0
                        marker:
                            enabled: true
                            radius: 2
                            symbol: 'circle'
                
                series.push serie_options
            
            technical_index++
    
    series:     series
    yAxis:      yAxis
    offset:     0


update_inline_technicals = (data_sources, instruments, technicals, offset, options) ->
    
    effective_offset = 0
    
    effective_instruments   = (instrument for instrument in instruments when !instrument.disabled)
    
    if _.size(effective_instruments) < 3
    
        effective_instrument    = _.first effective_instruments
        data_source             = data_sources[effective_instrument.id].technicals
    
        for technical in data_source when !!technical.inline
            for serie in technical.data
                options.chart.series[effective_offset + offset].setData(serie, false)
            
                effective_offset++
    
    effective_offset


create_separate_technicals = (data_sources, instruments, technicals, offset, options) ->
    
    series  = []
    yAxis   = []
    
    yAxis_offset_index  = 3
    effective_offset    = 0
    technical_index     = 0

    [effective_instrument, effective_index]  = _.first([instrument, index] for instrument, index in instruments when !instrument.disabled)
    data_source                                         = data_sources[effective_instrument.id].technicals
    
    for technical, index in data_source
        
        continue if technical.inline
        
        yAxis.push $.extend true, {}, default_volumes_yAxis_options,
            top: offset + effective_offset + volumes_yAxis_margin
        
        for serie in technical.data
            
            serie_options = $.extend true, {}, default_candles_series_options,
                id:     "separate technicals:#{technical_index}"
                name:   options.technicals_meta[technicals[index].id].title
                color:  scope.colors[effective_index]
                type:   cs_to_hs_types[technical.type]
                data:   serie
                yAxis:  yAxis_offset_index + _.size(yAxis) - 1
            
            series.push serie_options
        
        effective_offset += volumes_yAxis_margin + volumes_yAxis_height

        technical_index++
        
    series:     series
    yAxis:      yAxis
    offset:     effective_offset


update_separate_technicals = (data_sources, instruments, technicals, offset, options) ->
    effective_offset = 0
    
    effective_instrument   = _.first(instrument for instrument in instruments when !instrument.disabled)
    data_source            = data_sources[effective_instrument.id].technicals
    
    for technical in data_source when !technical.inline
        for serie in technical.data
            options.chart.series[effective_offset + offset].setData(serie, false)
            
            effective_offset++
    
    effective_offset


calculate_extremes = (chart, options) ->
    { min, max } = _.first(chart.xAxis).getExtremes()
    
    if !options.left_lock and !options.right_lock
        min = options.min if options.min > min and options.min < max
        max = options.max if options.max < max and options.max > min
    else if options.left_lock and !options.right_lock
        delta   = min - options.min
        max     = options.max + delta if options.max + delta < max
    else if !options.left_lock and options.right_lock
        delta   = max - options.max
        min     = options.min + delta if options.min + delta > min

    min: min
    max: max

create = (container, data_sources, instruments, technicals, chart_type, options = {}) ->
    
    series  = []
    xAxis   = []
    yAxis   = []
    
    offset  = 0
    
    ###
        CANDLES
    ###
    
    candles = create_candles data_sources, instruments, chart_type
    series.push     candles.series...
    yAxis.push      candles.yAxis...
    offset +=       candles.offset
    
    ###
        VOLUMES
    ###
    
    volumes = create_volumes data_sources, instruments
    series.push     volumes.series...
    yAxis.push      volumes.yAxis...
    offset +=       volumes.offset
    
    ###
        INLINE TECHNICALS
    ###
    
    inline_technicals = create_inline_technicals data_sources, instruments, technicals, offset, options
    series.push     inline_technicals.series...
    yAxis.push      inline_technicals.yAxis...
    offset +=       inline_technicals.offset
    
    ###
        SEPARATE TECHNICALS
    ###
    
    separate_technicals = create_separate_technicals data_sources, instruments, technicals, offset, options
    series.push     separate_technicals.series...
    yAxis.push      separate_technicals.yAxis...
    offset +=       separate_technicals.offset
    
    ###
        XAXIS
    ###
    
    xAxis.push $.extend true, {}, default_xAxis_options,
        height: offset + default_xAxis_margin
        events:
            setExtremes: options.on_extremes_change
    
    offset += default_xAxis_margin + default_xAxis_height
    
    ###
        NAVIGATOR
    ###
    
    offset += navigator_height + scrollbar_height
    
    ###
        CHART
    ###

    chart_options = $.extend true, {}, default_chart_options,
        chart:
            renderTo:   _.first(container)
            height:     offset
        tooltip:

            formatter: ->
                render_tooltips chart, @
                

        series: series
        xAxis:  xAxis
        yAxis:  yAxis
    
    options.chart.destroy() if options.chart?
    
    chart = new Highcharts.StockChart chart_options
    
    { min, max } = calculate_extremes chart, options
    _.first(chart.xAxis).setExtremes(min, max, true, false)
    
    container.css 'height', chart.chartHeight

    chart


update = (container, data_sources, instruments, technicals, chart_type, options = {}) ->
    
    chart   = options.chart
    offset  = 0
    
    ###
        UPDATE CANDLES
    ###
    
    offset += update_candles data_sources, instruments, chart_type, offset, options
    
    ###
        UPDATE VOLUMES
    ###
    
    offset += update_volumes data_sources, instruments, offset, options
    
    ###
        UPDATE INLINE TECHNICALS
    ###
    
    offset += update_inline_technicals data_sources, instruments, technicals, offset, options

    ###
        UPDATE SEPARATE TECHNICALS
    ###
    
    offset += update_separate_technicals data_sources, instruments, technicals, offset, options
    
    ###
        UPDATE CHART
    ###

    { min, max } = calculate_extremes chart, options
    _.first(chart.xAxis).setExtremes(min, max, true, false)

    chart.redraw()
    
    chart




calculate_technicals_colors_indices = (technicals, instruments, data_sources) ->
    total_instruments           = _.size instruments ; return [] if total_instruments == 0
    
    effective_instrument_index  = _.first(index for instrument, index in instruments when !instrument.disabled)
    
    inline_instrument_index = 0
    
    result = []
    
    for technical in data_sources[instruments[effective_instrument_index].id].technicals
        if technical.inline
            result.push total_instruments + inline_instrument_index
            inline_instrument_index++
        else
            result.push effective_instrument_index
    
    result



render_tooltips = (chart, state) ->

    # clear tooltips
    
    $('.tooltip', chart.container).remove()
    
    date = new Date(state.points[0].x)
    
    # prepare data
    
    __points = _.reduce(state.points, (memo, points) ->
        [id, index] = points.series.options.id.split(':')
        ((memo[id] ||= [])[index] ||= []).push(points)
        memo
    , {})

    # candles and inline technicals
    
    tooltip = $('<ul>')
        .addClass('tooltip')
        .css('top', 0)
        .appendTo(chart.container)
    
    # date
    
    $('<li>')
        .addClass('date')
        .html(Highcharts.dateFormat('%Y-%m-%d %H:%M', date))
        .appendTo(tooltip)
    
    # candles

    _.each(__points['candles'], (points) -> render_points_for_tooltip(tooltip, points))

    # inline technicals
    
    _.each(__points['inline technicals'], (points) -> render_points_for_tooltip(tooltip, points))
    
    # volumes
    
    offset = candles_yAxis_margin + candles_yAxis_height

    tooltip = $('<ul>')
        .addClass('tooltip')
        .css('top', offset)
        .appendTo(chart.container)
    
    $('<li>')
        .addClass('date')
        .html(Highcharts.dateFormat('%Y-%m-%d %H:%M', date))
        .appendTo(tooltip)
    
    _.each(__points['volumes'], (points) -> render_points_for_tooltip(tooltip, points))

    
    # separate technicals
    
    offset = candles_yAxis_margin + candles_yAxis_height + volumes_yAxis_margin + volumes_yAxis_height
    
    _.each(__points['separate technicals'], (points, index) ->
        
        tooltip = $('<ul>')
            .addClass('tooltip')
            .css('top', offset + (volumes_yAxis_margin + volumes_yAxis_height) * index)
            .appendTo(chart.container)
        
        $('<li>')
            .addClass('date')
            .html(Highcharts.dateFormat('%Y-%m-%d %H:%M', date))
            .appendTo(tooltip)
    

        render_points_for_tooltip(tooltip, points)
        
    )
    
    false

render_points_for_tooltip = (container, points) ->
    view = $('<li>')
        .appendTo(container)
    
    $('<em>')
        .html(points[0].series.name)
        .css('color', points[0].series.color)
        .appendTo(view)

    _.each(points, (point) -> render_point_for_tooltip(view, point))


render_point_for_tooltip = (container, point) ->
    switch point.series.type
        when 'line', 'column'
            $('<span>')
                .html(point.point.y)
                .appendTo(container)
        when 'candlestick', 'ohlc'
            _.each(['open', 'high', 'low', 'close'], (key) ->
                $('<span>')
                    .html(key + ': ' + point.point[key])
                    .appendTo(container)
            )



widget = (wrapper, options = {}) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    deferred = new $.Deferred
    
    chart_wrapper               = $('.chart_wrapper', wrapper)
    chart_candle_width_wrapper  = $('.chart_candle_widths_wrapper', wrapper)
    chart_type_wrapper          = $('.chart_types_wrapper', wrapper)
    instruments_wrapper         = $('.instruments_wrapper', wrapper)
    technicals_wrapper          = $('.technicals_wrapper', wrapper)
    
    chart_candle_width          = mx.data.chart_candle_width(chart_candle_width_wrapper)
    chart_type                  = mx.data.chart_type(chart_type_wrapper);
    instruments                 = mx.data.chart_instruments(instruments_wrapper)
    technicals                  = mx.data.chart_technicals(technicals_wrapper)
            
    data_sources                = {}
    technicals_meta             = {}
            
    should_rebuild              = true
    refresh_timeout             = undefined
            
    chart                       = undefined


    ready_for_render = $.when chart_candle_width, chart_type, instruments, technicals


    render = ->
        $.when(_.values(data_sources)...).then ->
            
            cached_extremes = cache.get 'extremes'
            
            { min, max, dataMin, dataMax } = if cached_extremes?
                cached_extremes
            else if chart?
                _.first(chart.xAxis).getExtremes()
            else
                {}

            create_or_update = if !chart? or should_rebuild then create else update
            
            validated_instruments   = validate_instruments instruments.data(), data_sources
            valid_instruments       = (instrument for instrument in validated_instruments when !instrument.failure?)
            
            if _.size(valid_instruments) > 0
                chart = create_or_update chart_wrapper, data_sources, validated_instruments, technicals.data(), chart_type.data(),
                    chart:              chart
                    min:                min
                    max:                max
                    left_lock:          min? and min == dataMin
                    right_lock:         max? and max == dataMax
                    on_extremes_change: cache_extremes
                    technicals_meta:    technicals_meta
                
            else
                if chart?
                    chart.destroy() ; chart = undefined
                chart_wrapper.css('height', '').html(no_data())
            
            should_rebuild          = false
            
            $(window).trigger 'chart:render:complete'
            $(window).trigger 'chart:indicators:colors', [calculate_technicals_colors_indices(technicals.data(), instruments.data(), data_sources)]
            

    delayed_render = ->
        if should_rebuild == true and chart?
            chart.showLoading()

        _.delay render, 50
    
    
    cache_extremes = (event) ->
        { dataMin, dataMax } = event.currentTarget.getExtremes()
        
        cache.set 'extremes',
            min:        event.min
            max:        event.max
            dataMin:    dataMin
            dataMax:    dataMax
    

    data_source_for_instrument = (instrument) ->
        interval    = chart_candle_width.data().interval
        duration    = chart_candle_width.data().duration
        period      = "#{Math.ceil(duration / 120)}d"
        
        mx.cs.highstock_2 instrument.id,
            interval:   interval
            period:     period
            technicals: technicals.data()
    

    refresh = ->
        clearTimeout refresh_timeout
        
        data_sources = _.reduce instruments.data(), (memo, instrument) ->
            memo[instrument.id] = data_source_for_instrument instrument ; memo
        , {}

        delayed_render()

        $.when(_.values(data_sources)...).then -> refresh_timeout = _.delay refresh, refresh_delay


    change_chart_candle_width = ->
        should_rebuild = true ; refresh()


    change_chart_type = ->
        should_rebuild = true ; delayed_render()


    change_instruments = (event, instruments, message) ->
        switch message
            when 'add'
                data_sources[instrument.id] ?= data_source_for_instrument instrument for instrument in instruments
            when 'remove'
                delete data_sources[key] for key in _.difference _.keys(data_sources), _.pluck(instruments, 'id')

        should_rebuild = true ; delayed_render()


    change_technicals = ->
        should_rebuild = true ; refresh()


    ready_for_render.then ->

        $(window).on 'chart:candle_width:changed',  change_chart_candle_width
        $(window).on 'chart:type:changed',          change_chart_type
        $(window).on 'chart:instruments:changed',   change_instruments
        $(window).on 'chart:technicals:changed',    change_technicals
        
        technicals_meta = _.reduce technicals.meta(), (memo, item) ->
            memo[item.id] = item ; memo
        , {}
        
        refresh()
        
        deferred.resolve()
        
    deferred.promise()


$.extend scope,
    chart: widget
