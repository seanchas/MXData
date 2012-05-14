root    = @
scope   = root['mx']['data']


$       = jQuery

cache = kizzy('data.chart')

default_candle_width    = 240

max_instruments = 5


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
        alignTicks: true
        height: 470
    
    credits:
        enabled: false
    
    rangeSelector:
        enabled: false
    
    navigator:
        height: 50
    
    scrollbar:
        height: 15
    
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
    height: 370
    top: 0
    offset: 0
    id: null


# default y axis options

default_yaxis_options =
    lineWidth: 1
    height: 250
    top: 0
    offset: 0
    showEmpty: false

# default volumnes y axis options

default_volumes_yaxis_options =
    lineWidth: 1
    height: 100
    top: 260
    offset: 0
    showEmpty: false
    alignTicks: false


_make_chart = (container, candles_data, volumes_data, options = {}) ->
    chart_options = $.extend true, {}, default_chart_options
    
    series  = []
    xAxis   = []
    yAxis   = []
    
    
    xAxis.push $.extend true, {}, default_xaxis_options

    yAxis.push $.extend true, {}, default_yaxis_options

    yAxis.push $.extend true, {}, default_yaxis_options,
        opposite: true
        gridLineWidth: 0


    candles_data_size = _.size candles_data
    
    for serie, index in candles_data
        serie_options = $.extend true, {}, default_series_options
        
        $.extend serie_options,
            color: colors[index]
            type:   chart_types_mapping[serie.type]
            data:   serie.data
            yAxis:  if index == 1 and candles_data_size == 2 then 1 else 0
        
            if candles_data_size > 2
                $.extend true, serie_options,
                compare: 'value'
    
        series.push serie_options
    
    
    # volumes
    
    volumes_yaxis_index = _.size yAxis
    
    yAxis.push $.extend true, {}, default_volumes_yaxis_options

    for serie, index in _.first(volumes_data, if _.size(volumes_data) > 2 then 1 else 2)
        
        serie_options = $.extend true, {}, default_volumes_series_options

        $.extend true, serie_options,
            color: colors[index]
            type: chart_types_mapping[serie.type]
            data: serie.data
            yAxis: volumes_yaxis_index

        series.push serie_options

    $.extend true, chart_options,
        chart:
            renderTo: _.first(container)
        series: series
        xAxis:  xAxis
        yAxis:  yAxis
    

    options.chart.destroy() if options.chart
    chart = new Highcharts.StockChart chart_options
    

    xaxis = _.first chart.xAxis

    { min, max } = xaxis.getExtremes()
    
    if min < options.min and max >= options.min then min = options.min
    if max > options.max and min <= options.min then max = options.max unless options.max_lock == true

    xaxis.setExtremes(min, max, true, false)
    

    chart



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
    
    chart = options.chart ; chart.destroy if chart?
    
    chart_options = $.extend true, {}, default_chart_options
    
    series  = []
    xAxis   = []
    yAxis   = []
    
    xAxis.push $.extend true, {}, default_xaxis_options,
        events:
            setExtremes: options.onExtremesChange

    yAxis.push $.extend true, {}, default_yaxis_options

    yAxis.push $.extend true, {}, default_yaxis_options,
        opposite: true
        gridLineWidth: 0

    yAxis.push $.extend true, {}, default_volumes_yaxis_options
    
    
    size = _.size data
    
    instrument_index = 0
    
    for datum, index in data

        instrument_index++ while options.instruments[instrument_index].__disabled == true

        [ candles, volumes ] = datum
        
        candles = _.first(candles)
        volumes = _.first(volumes)

        # candles
        
        candles_serie_options = $.extend true, {}, default_series_options

        $.extend candles_serie_options,
            color:  colors[instrument_index]
            type:   chart_types_mapping[if index > 1 or size > 2 then 'line' else candles.type]
            data:   candles.data
            yAxis:  if size == 2 and index == 1 then 1 else 0

        if size > 2
            $.extend candles_serie_options,
                compare: 'value'
        
        series.push candles_serie_options

        # volumes

        if size == 2 or index == 0
            volumes_serie_options = $.extend true, {}, default_volumes_series_options
            
            $.extend true, volumes_serie_options,
                color:  colors[instrument_index]
                type:   chart_types_mapping[volumes.type]
                data:   volumes.data
                yAxis:  2

            series.push volumes_serie_options
        
        instrument_index++
            

    $.extend true, chart_options,
        chart:
            renderTo: _.first(container)
        series: series
        xAxis:  xAxis
        yAxis:  yAxis


    chart = new Highcharts.StockChart chart_options
    
    { min, max } = _process_chart_extremes(chart, options) ; chart.xAxis[0].setExtremes(min, max, true, false)
    
    container.css('height', container.height())

    chart
    
    
_update_chart = (container, data, options = {}) ->
    chart   = options.chart
    
    size    = _.size data
    index   = 0
    
    for datum in data
        
        [ candles, volumes ] = datum
        
        candles = _.first(candles)
        volumes = _.first(volumes)

        # candles
        
        serie       = chart.series[index]
        serie.setData(candles.data, false)
        index++
        
        # volumes
        
        if size == 2 or index == 1
            serie       = chart.series[index]
            serie.setData(volumes.data, false)
            index++

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
    
    # caches
    
    cached_extremes = undefined
    
    # deferreds
    
    init_type_deferred          = new $.Deferred
    init_interval_deferred      = new $.Deferred
    init_instruments_deferred   = new $.Deferred
    init_extremes_deferred      = new $.Deferred
    dom_ready                   = do -> $.when(chart_period_selector_deferred, chart_type_selector_deferred).then
    ready                       = do -> $.when(init_type_deferred, init_interval_deferred, init_instruments_deferred).then
    
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
            _create_chart chart_container, data, { chart: chart, instruments: instruments, type: current_type, min: min, max: max, leftLock: min == dataMin, rightLock: max == dataMax, onExtremesChange: onExtremesChange }
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
        
        sources = _.map(active_instruments, (instrument, index) -> mx.cs.highstock_2("#{instrument.board}:#{instrument.id}", { type: (if index == 0 then current_type else 'line'), interval: current_interval, period: "#{period}d" }))
        $.when(sources...).then render_2
        
    
    refresh = ->
        ready ->
            #fetch()
            render()
            _.delay refresh, 20 * 1000
        
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
    chart: widget
