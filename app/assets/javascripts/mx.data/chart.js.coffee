root    = @
scope   = root['mx']['data']


$       = jQuery

cache = kizzy('data.chart')


default_candle_width = 240

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
    mx.data.ready.then (metadata) ->

        for duration in metadata.durations
            item = $('<li>')
                .html(duration.title)
                .attr('data-interval', duration.interval)
                .attr('data-duration', duration.duration)
            
            item.addClass('selected') if duration.interval == 10
            
            container.append item

make_chart_type_selector = (container) ->
    selector = $("<select>")
        .attr("id", "chart-type-selector")
    
    for chart_type in chart_types
        selector.append $("<option>")
            .attr("value", chart_type)
            .html(chart_types_titles[chart_type])
    
    container.html selector


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

    ###
widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    securities  = []
    
    make_content wrapper

    make_chart_period_selector $('#chart-period-selector-container', wrapper)
    make_chart_type_selector $('#chart-type-selector-container', wrapper)

    chart_container = $('#chart-container', wrapper)
    chart           = _make_chart chart_container, [{ data: [] }], [{ data: [] }]
    
    chart_type_selector = $('select#chart-type-selector')
    chart_type          = _.first chart_types
    
    refresh_timeout = undefined
    
    # interface
    
    is_security_included = (param) ->
        _.include securities, param

    addSecurity = (param) ->
        clearTimeout refresh_timeout

        included = is_security_included param
        securities.push param unless included

        refresh_timeout = _.delay refresh, 300
    
    removeSecurity = (param) ->
        clearTimeout refresh_timeout

        included = is_security_included param
        securities = _.without securities, param if included
        
        refresh_timeout = _.delay refresh, 300
    
    setChartType = (new_chart_type) ->
        chart_type = new_chart_type if _.include chart_types, new_chart_type
        refresh()
    
    # refresh
    
    refresh = ->
        chart.showLoading()
        
        mx.cs.highstock(securities, { type: chart_type }).then (json) ->
            [candles, volumes] = json
            
            { min, max } = _.first(chart.xAxis).getExtremes()
            
            chart = _make_chart chart_container, candles, volumes, { chart: chart, min: min, max: max }
                    
    
    addSecurity('stock:index:SNDX:MICEXINDEXCF')
    addSecurity('currency:basket:BKT:USDEUR_BKT')
    
    # event observers
    
    onChartTypeSelectorChange = (event) ->
        setChartType chart_type_selector.val()

    # event listeners
    
    chart_type_selector.on "change", onChartTypeSelectorChange
    
###

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
    
    make_chart_period_selector chart_periods_container
    
    current_type        = undefined
    current_interval    = undefined
    current_duration    = undefined
    instruments         = []
    
    instruments_cached  = false
    
    render_timeout  = undefined
    
    chart           = undefined
    
    # utilities
    
    should_be_enabled = ->
        _.size(instruments) == _.size(instrument for instrument in instruments when instrument.__disabled == true)
    
    # interface
    
    setType = (type) ->
        item = $("li[data-type=#{type}]", chart_types_container) ; return if _.size(item) == 0

        item.siblings().removeClass('selected')
        item.addClass('selected')

        current_type = type
        
        render()
    
    setInterval = (interval) ->
        item = $("li[data-interval=#{interval}]", chart_periods_container) ; return if _.size(item) == 0
        
    
        item.siblings().removeClass('selected')
        item.addClass('selected')
    
        current_interval = interval
        current_duration = item.data('duration')
        
        render()
    

    toggleInstrumentState = (param) ->
        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?

        instrument.__disabled = !instrument.__disabled
        instrument.__disabled = false if should_be_enabled()

        renderInstruments()

    addInstrument = (new_instrument) ->
        return if _.size(instruments) >= max_instruments
        instrument = _.first(instrument for instrument in instruments when instrument.id == new_instrument.id)
        return if instrument?
        
        return if new_instrument.no_cache and instruments_cached == true

        delete new_instrument.no_cache

        instruments.push(new_instrument)

        cache.set("#{cache_key}:instruments", instruments)

        renderInstruments()
    

    removeInstrument = (param) ->
        return unless _.size(instruments) > 1

        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?

        instruments = _.without(instruments, instrument)
        _.first(instruments).__disabled = false if should_be_enabled()
        
        cache.set("#{cache_key}:instruments", instruments)

        renderInstruments()
    

    clearInstruments = ->
        #delete instruments
        #instruments = []
        #renderInstruments()
    

    reorderInstruments = ->
        sorted_instruments = ( $(item).data('param') for item in $('li', chart_instruments_container) )
        instruments = _.sortBy instruments, (item) -> _.indexOf sorted_instruments, item.id

        cache.set("#{cache_key}:instruments", instruments)

        renderInstruments()


    # renders
    
    renderInstruments = ->
        chart_instruments_container.empty()
        count = _.size(instruments)
        for instrument, index in instruments
            chart_instruments_container.append make_instrument_view(instrument, colors[index], { count: count })

        render()
    
    render = ->
        clearTimeout render_timeout
        return unless _.size(instruments) > 0
        render_timeout = _.delay ->
            
            if chart?
                chart.showLoading()
            
            period = Math.ceil(current_duration / 120) || 1
            
            mx.cs.highstock(instruments, { type: current_type, interval: current_interval, period: "#{period}d" }).then (json) ->
                
                max_lock = if chart?
                    extremes = _.first(chart.xAxis).getExtremes()
                    extremes.max == extremes.dataMax
                else
                    false
                
                [candles, volumes] = json
                { min, max } =  if chart? then _.first(chart.xAxis).getExtremes() else { min: undefined, max: undefined }
                chart = _make_chart chart_container, candles, volumes, { chart: chart, min: min, max: max, max_lock: max_lock }
            
        , 300
    
    reload = ->
        render()
        _.delay reload, 20 * 1000
        
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

    # initialization
    
    setType(_.first(type.name for type in chart_types when type.is_default))
    
    setInterval(10)

    $(chart_instruments_container).sortable
        axis: 'x'
        update: reorderInstruments

    # restore from cache

    cached_instruments = cache.get("#{cache_key}:instruments")
    instruments_cached = !!cached_instruments

    if instruments_cached
        for instrument in cached_instruments
            addInstrument instrument
    
    reload()

    # returned interface
    
    {
        setType:            setType
        setInterval:        setInterval
        addInstrument:      addInstrument
        removeInstrument:   removeInstrument
        clearInstruments:   clearInstruments
    }
    

$.extend scope,
    chart: widget
