root    = @
scope   = root['mx']['data']


$       = jQuery

cache = kizzy('data.chart')


fetch_chart_type = 'candles'


refresh_delay    = 20 * 1000


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
        alignTicks: false
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
        column:
            lineWidth: 1
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
    showEmpty:  false
    alignTicks: false


default_xAxis_options =
    top:    0
    offset: 0


create_candles = (data_sources, instruments, chart_type) ->
    
    series  = []
    yAxis   = []

    yAxis.push $.extend true, {}, default_candles_yAxis_options
    
    yAxis.push $.extend true, {}, default_candles_yAxis_options,
        opposite:       true
        gridLineWidth:  0


    effective_instruments_size  = _.size(instrument for instrument in instruments when !instrument.disabled)
    effective_index             = 0
    
    for instrument, index in instruments
        continue if instrument.disabled == true
        
        effective_chart_type = if effective_index > 0 or effective_instruments_size > 2 then 'line' else chart_type

        candles         = _.first data_sources[instrument.id].candles
        candles_data    = candles["#{if effective_chart_type == 'line' then 'line' else 'candles'}_data"]
        
        candles_serie_options = $.extend true, {}, default_candles_series_options,
            name:   instrument.title
            color:  scope.colors[index]
            type:   cs_to_hs_types[effective_chart_type]
            data:   candles_data
            yAxis:  if effective_instruments_size == 2 and effective_index == 1 then 1 else 0
        
        if effective_instruments_size > 2
            $.extend candles_serie_options,
                compare: 'percent'

        series.push candles_serie_options
        
        effective_index++
    
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
            name:   instrument.title
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
    
    for instrument, index in instruments
        break if effective_instruments_size > 2 and effective_index > 0
        break if effective_index > 1

        continue if instrument.disabled == true
        
        volumes         = _.first data_sources[instrument.id].volumes
        volumes_data    = volumes.data
        
        options.chart.series[effective_index + offset].setData(volumes_data, false)
        
        effective_index++
    
    effective_index


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

create = (container, data_sources, instruments, chart_type, options = {}) ->
    
    series  = []
    xAxis   = []
    yAxis   = []
    
    offset  = 0
    
    ###
        CANDLES
    ###
    
    candles = create_candles data_sources, instruments, chart_type
    series.push candles.series...
    yAxis.push  candles.yAxis...
    offset += candles.offset
    
    ###
        VOLUMES
    ###
    
    volumes = create_volumes data_sources, instruments
    series.push volumes.series...
    yAxis.push  volumes.yAxis...
    offset += volumes.offset
    
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
        series: series
        xAxis:  xAxis
        yAxis:  yAxis
    
    options.chart.destroy() if options.chart?
    
    chart = new Highcharts.StockChart chart_options
    
    { min, max } = calculate_extremes chart, options
    _.first(chart.xAxis).setExtremes(min, max, true, false)
    
    container.css 'height', chart.chartHeight
    
    chart


update = (container, data_sources, instruments, chart_type, options = {}) ->
    
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
        UPDATE CHART
    ###

    { min, max } = calculate_extremes chart, options
    _.first(chart.xAxis).setExtremes(min, max, true, false)

    chart.redraw()
    
    chart


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
            
            chart = create_or_update chart_wrapper, data_sources, instruments.data(), chart_type.data(),
                chart:              chart
                min:                min
                max:                max
                left_lock:          min? and min == dataMin
                right_lock:         max? and max == dataMax
                on_extremes_change: cache_extremes
            
            should_rebuild          = false
            
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

        mx.cs.highstock_2 "#{instrument.board}:#{instrument.id}",
            interval:   interval
            period:     period
    

    refresh = ->
        clearTimeout refresh_timeout
        
        delete data_sources
        
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
        console.log 'technicals'


    ready_for_render.then ->

        $(window).on 'chart:candle_width:changed',  change_chart_candle_width
        $(window).on 'chart:type:changed',          change_chart_type
        $(window).on 'chart:instruments:changed',   change_instruments
        $(window).on 'chart:technicals:changed',    change_technicals
        
        refresh()
        
        deferred.resolve()
        
    deferred.promise()


$.extend scope,
    chart: widget
