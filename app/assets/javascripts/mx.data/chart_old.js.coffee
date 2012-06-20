root    = @
scope   = root['mx']['data']


$       = jQuery

cache = kizzy('data.chart')

default_candle_width    = 240

max_instruments = 5


candles_yaxis_margin = 30
candles_yaxis_height = 250

volumes_yaxis_margin = 30
volumes_yaxis_height = 100

default_xaxis_margin = 30
default_xaxis_height = 25

navigator_height = 50
scrollbar_height = 15

colors = [
    '#4572a7'
    '#aa4643'
    '#89a54e'
    '#80699b'
    '#3d96ae'
    '#db843d'
    '#92a8cd'
    '#a47d7c'
    '#b5ca92'
]


chart_periods = [
    {
        name:       'day'
        title:      'День'
        interval:   10
        period:     '2d'
        candles:    240
        is_default: true
    }
    {
        name:       'week'
        title:      'Неделя'
        interval:   60
        period:     '2w'
    }
    {
        name:       'month'
        title:      'Месяц'
        interval:   24
        period:     '2m'
    }
    {
        name:       'year'
        title:      'Год'
        interval:   7
        period:     '2y'
    }
    {
        name:       'all'
        title:      'Весь период'
    }
]

    
chart_types = [
    {
        name:       'candles'
        title:      'Свечи'
        is_default: true
    }
    {
        name:       'stockbar'
        title:      'Бары'
    }
    {
        name:       'line'
        title:      'Линия'
    }
]


chart_types_mapping =
    line:       'line'
    candles:    'candlestick'
    stockbar:   'ohlc'
    bar:        'column'


instruments_amount_margins =
    min:    1
    max:    5


make_content = (container) ->
    container.html("<div id=\"chart-period-selector-container\"></div><div id=\"chart-type-selector-container\"></div><div id=\"chart-container\"></div>")    


make_chart_period_selector = (container) ->
    deferred = new $.Deferred
    
    mx.data.ready.then (metadata) ->

        for duration in metadata.durations
            item = $('<li>')
                .html(duration.title)
                .attr('data-interval', duration.interval)
                .attr('data-duration', duration.duration)
            
            item.addClass('selected') if duration.interval == 10
            
            container.append item

        deferred.resolve()
    
    deferred.promise()

make_chart_type_selector = (container) ->
    deferred = new $.Deferred
    
    deferred.resolve()
    
    deferred.promise()


# default chart options

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
        #formatter: ->
        #    false
    
    plotOptions:
        ohlc:
            lineWidth: 2
        column:
            lineWidth: 1
        series:
            gapSize: 60
            dataGrouping:
                enabled: false

# default series options

default_series_options =
    dataGrouping:
        smoothed: true

# default volumes series options

default_volumes_series_options =
    dataGrouping:
        smoothed: true


# default x axis options

default_xaxis_options =
    top: 0
    offset: 0
    id: null


# default y axis options

default_yaxis_options =
    lineWidth: 1
    height: candles_yaxis_height
    top: candles_yaxis_margin
    offset: 0
    showEmpty: false

# default volumnes y axis options

default_volumes_yaxis_options =
    lineWidth: 1
    height: volumes_yaxis_height
    top: candles_yaxis_margin + candles_yaxis_height + volumes_yaxis_margin
    offset: 0
    showEmpty: false
    alignTicks: false



_process_serie_indicators = (data) ->
    _.flatten _.reduce(data, (container, item) ->
            id = parseInt item.id[0].match /\d+$/
            (container[id] ?= []).push
                type: item.type
                data: item.data
            container
        , [])
    , true


 _process_chart_extremes = (chart, options = {}) ->
    { min, max } = chart.xAxis[0].getExtremes()
    
    if options.leftLock and options.rightLock
        min = min
        max = max
    
    if !options.leftLock and !options.rightLock
        min = options.min if options.min > min and options.min < max
        max = options.max if options.max < max and options.max > min
    
    if options.leftLock and !options.rightLock
        delta = min - options.min
        max = options.max + delta if options.max + delta < max
    
    if !options.leftLock and options.rightLock
        delta = max - options.max
        min = options.min + delta if options.min + delta > min

    min: min
    max: max


_create_chart = (container, data, options = {}) ->
    
    size            = _.size data
    chart           = options.chart ; chart.destroy if chart?
    
    series  = []
    xAxis   = []
    yAxis   = []
    
    # candles

    # left candles y axis
    yAxis.push $.extend true, {}, default_yaxis_options

    # right candles y axis
    yAxis.push $.extend true, {}, default_yaxis_options,
        opposite: true
        gridLineWidth: 0

    instrument_index = 0

    for record, index in data

        candles = _.first record.candles

        instrument_index++ while options.instruments[instrument_index].__disabled == true
        instrument = options.instruments[instrument_index]

        candles_serie_options = $.extend true, {}, default_series_options

        $.extend candles_serie_options,
            name:   instrument.title
            color:  colors[instrument_index]
            type:   chart_types_mapping[candles.type]
            data:   candles.data
            yAxis:  if size == 2 and index == 1 then 1 else 0
        

        if size > 2
            $.extend candles_serie_options,
                compare: 'percent'
        
        series.push candles_serie_options
        
        instrument_index++
    
    # volumes
    
    # left volumes y axis
    yAxis.push $.extend true, {}, default_volumes_yaxis_options

    instrument_index = 0

    for record, index in data
        
        volumes = _.first record.volumes

        instrument_index++ while options.instruments[instrument_index].__disabled == true
        instrument = options.instruments[instrument_index]

        volumes_serie_options = $.extend true, {}, default_volumes_series_options
            
        $.extend true, volumes_serie_options,
            name:   instrument.title
            color:  colors[instrument_index]
            type:   chart_types_mapping[volumes.type]
            data:   volumes.data
            yAxis:  2

        series.push volumes_serie_options
        
        instrument_index++

    ###

    # candles technicals

    for candles_technicals, index in chart_data.candles_technicals
        candles_serie_options = $.extend true, {}, default_series_options
    
        $.extend candles_serie_options,
            color:  colors[_.size(options.instruments) + index]
            type:   chart_types_mapping[candles_technicals.type]
            data:   candles_technicals.data
            yAxis:  0
        
        series.push candles_serie_options
    
    ###

    offset = candles_yaxis_margin + candles_yaxis_height + volumes_yaxis_margin + volumes_yaxis_height
    
    for technicals, index in data[0].technicals
        
        if technicals.inline == true
            for technical_data in technicals.data
                serie_options = $.extend true, {}, default_series_options,
                    color: colors[_.size(data) + index]
                    data: technical_data
                    type: chart_types_mapping[technicals.type] 
                    yAxis: 0

                series.push serie_options
        else
            console.log 'n/a'
                

    ###

    # technicals
    
    for indicators in technicals
        yAxis.push $.extend true, {}, default_volumes_yaxis_options,
            top: offset + volumes_yaxis_margin
        
        yAxisIndex = _.size(yAxis) - 1
        
        for serie in indicators
            serie_options = $.extend true, {}, default_series_options,
                color: colors[0]
                type: chart_types_mapping[serie.type]
                data: serie.data
                yAxis: yAxisIndex

            series.push serie_options

        offset += volumes_yaxis_margin + volumes_yaxis_height
        

    ###

    # main x axis

    xAxis.push $.extend true, {}, default_xaxis_options,
        height: offset + default_xaxis_margin
        events:
            setExtremes: options.onExtremesChange

    # chart
    
    chart_options   = $.extend true, {}, default_chart_options,
        chart:
            height: offset + default_xaxis_margin + default_xaxis_height + navigator_height + scrollbar_height
        tooltip:
            formatter: options.tooltip

    $.extend true, chart_options,
        chart:
            renderTo: _.first(container)
        series: series
        xAxis:  xAxis
        yAxis:  yAxis

    chart = new Highcharts.StockChart chart_options
    
    { min, max } = _process_chart_extremes(chart, options) ; chart.xAxis[0].setExtremes(min, max, true, false)
    
    container.css('height', chart.chartHeight)
    
    chart
    
    
_update_chart = (container, data, options = {}) ->
    chart   = options.chart

    size    = _.size data

    ###

    chart_data      =
        candles: []
        volumes: []
        candles_technicals: []
    
    technicals = _.reduce _.rest(data[0], 2), (container, item) ->
        container.push _process_serie_indicators(item)
        container
    , []

    for entry, index in data
        chart_data.candles.push entry[0][0]
        chart_data.volumes.push entry[1][0] if index == 0 or size == 2
        chart_data.candles_technicals.push _.rest(entry[0], 1)... if index == 0
    
    ###
    
    offset = 0
    
    for record, index in data
        candles = _.first record.candles
        chart.series[index + offset].setData(candles.data, false)
    
    offset += _.size data
    
    for record, index in data
        volumes = _.first record.volumes
        chart.series[index + offset].setData(volumes.data, false)
    
    offset += _.size data

    #for values, index in chart_data.candles_technicals
    #    chart.series[index + offset].setData(values.data, false)

    #offset += _.size chart_data.candles_technicals

    #for indicators, index in technicals
    #    for values, shift in indicators
    #        chart.series[index + shift + offset].setData(values.data, false)

    chart.redraw()

    { min, max } = _process_chart_extremes(chart, options) ; chart.xAxis[0].setExtremes(min, max, true, false)

    chart


make_instrument_view = (instrument, color, options = {}) ->
    view = $('<li>')
        .attr('data-param', instrument.id)
        .css('color', color)
        .toggleClass('disabled', instrument.__disabled == true)
        .html("#{instrument.title}")
    
        view.addClass('removeable').append($('<span>')) if options.count > 1
    
    view

widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    cache_key = ""
    
    chart_periods_container     = $('#chart_periods', wrapper)
    chart_types_container       = $('#chart_types', wrapper)
    chart_container             = $('#chart_container', wrapper)
    chart_instruments_container = $('#chart_instruments', wrapper)
    
    chart_period_selector_deferred  = make_chart_period_selector chart_periods_container
    chart_type_selector_deferred    = make_chart_type_selector chart_types_container
    
    current_type        = undefined
    current_interval    = undefined
    current_duration    = undefined
    instruments         = []
    
    instruments_cached  = false
    
    render_timeout  = undefined
    
    chart           = undefined
    
    stored_data     = undefined
    params_changed  = false
    
    
    technicals = []
    
    
    # caches
    
    cached_extremes = undefined
    
    # deferreds
    
    init_type_deferred          = new $.Deferred
    init_interval_deferred      = new $.Deferred
    init_instruments_deferred   = new $.Deferred
    init_extremes_deferred      = new $.Deferred
    dom_ready                   = do -> $.when(chart_period_selector_deferred, chart_type_selector_deferred).then
    ready                       = do -> $.when(init_type_deferred, init_interval_deferred, init_instruments_deferred).then
    
    candles_tooltip             = undefined
    volumes_tooltip             = undefined
    
    # utilities
    
    should_be_enabled = ->
        _.size(instruments) == _.size(instrument for instrument in instruments when instrument.__disabled == true)
    
    # interface
    
    setType = (type) ->
        item = $("li[data-type=#{type}]", chart_types_container) ; return if _.size(item) == 0

        item.siblings().removeClass('selected')
        item.addClass('selected')

        current_type = type
        
        params_changed = true
        init_type_deferred.resolve()

        cache.set "#{cache_key}:type", current_type
        
        render()
        
    setInterval = (interval) ->
        item = $("li[data-interval=#{interval}]", chart_periods_container) ; return if _.size(item) == 0
        
    
        item.siblings().removeClass('selected')
        item.addClass('selected')
    
        current_interval = interval
        current_duration = item.data('duration')
        
        params_changed = true
        init_interval_deferred.resolve()

        cache.set "#{cache_key}:interval", current_interval

        render()
    

    toggleInstrumentState = (param) ->
        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?

        instrument.__disabled = !instrument.__disabled
        instrument.__disabled = false if should_be_enabled()
        
        cache.set("#{cache_key}:instruments", instruments)

        params_changed = true

        renderInstruments()

    addInstrument = (new_instrument) ->
        return unless new_instrument?
        
        return if _.size(instruments) >= max_instruments

        instrument = _.first(instrument for instrument in instruments when instrument.id == new_instrument.id)
        return if instrument?
        
        return if new_instrument.no_cache and instruments_cached == true

        delete new_instrument.no_cache

        instruments.push(new_instrument)

        cache.set("#{cache_key}:instruments", instruments)

        params_changed = true
        init_instruments_deferred.resolve()

        renderInstruments()
    

    removeInstrument = (param) ->
        return unless _.size(instruments) > 1

        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?

        instruments = _.without(instruments, instrument)
        _.first(instruments).__disabled = false if should_be_enabled()
        
        cache.set("#{cache_key}:instruments", instruments)

        params_changed = true

        renderInstruments()
    

    clearInstruments = ->
        #delete instruments
        #instruments = []
        #renderInstruments()
    

    reorderInstruments = ->
        sorted_instruments = ( $(item).data('param') for item in $('li', chart_instruments_container) )
        instruments = _.sortBy instruments, (item) -> _.indexOf sorted_instruments, item.id

        cache.set("#{cache_key}:instruments", instruments)

        params_changed = true

        renderInstruments()
    
    onExtremesChange = (extremes) ->
        cache.set "#{cache_key}:extremes",
            min: extremes.min
            max: extremes.max
    
    onTechnicalsUpdated = (data) ->
        technicals = (technical.id for technical in data when !technical.disabled)

        params_changed = true
        
        render()


    # renders
    
    renderInstruments = ->
        chart_instruments_container.empty()
        count = _.size(instruments)
        for instrument, index in instruments
            chart_instruments_container.append make_instrument_view(instrument, colors[index], { count: count })

        render()
    
    render = ->
        ready ->
            
            clearTimeout render_timeout
            return unless _.size(instruments) > 0
            render_timeout = _.delay ->
            
                fetch()
                ###
                if chart? and params_changed
                    chart.showLoading()
            
                period = Math.ceil(current_duration / 120) || 1
            
                mx.cs.highstock(instruments, { type: current_type, interval: current_interval, period: "#{period}d" }).then (json) ->
                

                    delete stored_data if stored_data?

                    max_lock = if chart?
                        extremes = _.first(chart.xAxis).getExtremes()
                        extremes.max == extremes.dataMax
                    else
                        false
                
                    [candles, volumes] = json
                    { min, max } =  if chart? then _.first(chart.xAxis).getExtremes() else { min: undefined, max: undefined }
                    chart = _make_chart chart_container, candles, volumes, { chart: chart, min: min, max: max, max_lock: max_lock }
            
                    stored_data = json
                    params_changed = false
                
                
                    chart_container.css('height', chart_container.height())
                    ###
                
            , 300
    
    render_2 = (data...) ->
        
        { min, max, dataMin, dataMax } = if cached_extremes? 
            { min: cached_extremes.min, max: cached_extremes.max }
        else if chart?
            chart.xAxis[0].getExtremes()
        else
            { min: undefined, max: undefined, dataMin: undefined, dataMax: undefined }
        
        chart = if !chart? or params_changed
            candles_tooltip = undefined
            volumes_tooltip = undefined
            _create_chart chart_container, data, { chart: chart, instruments: instruments, type: current_type, min: min, max: max, leftLock: min == dataMin, rightLock: max == dataMax, onExtremesChange: onExtremesChange, tooltip: render_tooltip }
        else
            _update_chart chart_container, data, { chart: chart, instruments: instruments, type: current_type, min: min, max: max, leftLock: min == dataMin, rightLock: max == dataMax }
            
        delete data ; data = null
        
        cached_extremes = undefined
        params_changed  = false
        
    fetch = ->
        if chart? and params_changed
            chart.showLoading()
        
        current_duration   ?= 10
        period              = Math.ceil(current_duration / 120)
        
        active_instruments = ( instrument for instrument in instruments when instrument.__disabled != true)
        
        sources = _.map(active_instruments, (instrument, index) -> mx.cs.highstock_2("#{instrument.board}:#{instrument.id}", { 
            type:       if index == 0 and _.size(active_instruments) <= 2 then current_type else 'line'
            interval:   current_interval
            period:     "#{period}d"
            technicals: if index == 0 then technicals else undefined
        }))

        $.when(sources...).then render_2
        
    
    refresh = ->
        ready ->
            #fetch()
            render()
            _.delay refresh, 20 * 1000
    
    # tooltip
    
    render_tooltip = ->
        candles_tooltip.destroy() if candles_tooltip?
        volumes_tooltip.destroy() if volumes_tooltip?
        
        renderer = chart.renderer

        # time
        
        time = new Date @x
        time = "#{time.getUTCDate()}/#{time.getUTCMonth() + 1}/#{time.getUTCFullYear()} #{time.getUTCHours()}:#{time.getUTCMinutes()}"
        
        # candles
        
        serie = chart.series[0]
        xaxis = serie.xAxis
        yaxis = serie.yAxis
        
        candles = []
        
        for point in @points
            continue if point.series.options.type == 'column'
            candles.push "<span style=\"color: #{point.series.color};\">#{point.series.name}</span>: #{point.y}"
            
        candles_tooltip = renderer.text(time + " | " + candles.join(' | '), 20, yaxis.top + 20).attr({ zIndex: 1000 })
        candles_tooltip.add()
        
        # volumes
        
        #serie = chart.series[1]
        #xaxis = serie.xAxis
        #yaxis = serie.yAxis
        
        #volumes = []

        #for point in @points
        #    continue unless point.series.options.type == 'column'
        #    volumes.push "<span style=\"color: #{point.series.color};\">#{point.series.name}</span>: #{point.y}"

        #volumes_tooltip = renderer.text(volumes.join(' | '), 20, yaxis.top + 20)
        #volumes_tooltip.add()

        false
    
        
    # initialization
    
    bootstrap = ->
        
        # read cached values
            
        cached_interval     = cache.get("#{cache_key}:interval")
        cached_type         = cache.get("#{cache_key}:type")
        cached_extremes     = cache.get("#{cache_key}:extremes")
        cached_instruments  = cache.get("#{cache_key}:instruments")
                        
        if cached_instruments?
            instruments_cached = true
            for instrument in cached_instruments
                addInstrument instrument

        $(chart_instruments_container).sortable
            axis: 'x'
            update: reorderInstruments

        dom_ready ->
            
            # event listeners

            chart_types_container.on "click", "li:not(.selected)", (event) ->
                setType $(event.currentTarget).data('type')
    
            chart_periods_container.on "click", "li:not(.selected)", (event) ->
                setInterval $(event.currentTarget).data('interval')
    
            chart_instruments_container.on "click", "li", (event) ->
                toggleInstrumentState $(event.currentTarget).data('param')

            chart_instruments_container.on "click", "li span", (event) ->
                event.stopPropagation()
                removeInstrument $(event.currentTarget).closest('li').data('param')

            chart_instruments_container.parent().on "click", "span.reset", (event) ->
                clearInstruments()
                
            # technicals
            
            $(window).on 'technicals:updated', (event, data) ->
                onTechnicalsUpdated data.technicals
            
            # start
            
            setType(cached_type ? 'candles')
            setInterval(cached_interval ? 10)
            
            refresh()
            
            ###
    console.log 'set interval'
    setInterval(10)

    $(chart_instruments_container).sortable
        axis: 'x'
        update: reorderInstruments

    # restore from cache
    
    cached_interval     = cache.get("#{cache_key}:interval")
    cached_type         = cache.get("#{cache_key}:type")
    cached_extremes     = cache.get("#{cache_key}:extremes")
    cached_instruments  = cache.get("#{cache_key}:instruments")

    instruments_cached = !!cached_instruments
    
    console.log 'set type'
    setType(cached_type ? _.first(type.name for type in chart_types when type.is_default))
    
    console.log cached_type

    if instruments_cached
        for instrument in cached_instruments
            addInstrument instrument
    
    ready ->
        
    refresh()
    ###
    
    bootstrap()

    # returned interface
    
    {
        addInstrument: (args...) -> dom_ready -> addInstrument args...
    }
    

$.extend scope,
    chart_old: widget
