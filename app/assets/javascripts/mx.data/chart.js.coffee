root    = @
scope   = root['mx']['data']


$       = jQuery


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
        is_default: true
    }
    {
        name:       'week'
        title:      'Неделя'
    }
    {
        name:       'month'
        title:      'Месяц'
    }
    {
        name:       'year'
        title:      'Год'
    }
    {
        name:       'all'
        title:      'Весь период'
    }
]

    
chart_types = [
    {
        name:       'line'
        title:      'Линия'
        is_default: true
    }
    {
        name:       'candles'
        title:      'Свечи'
    }
    {
        name:       'stockbar'
        title:      'Бары'
    }
]


chart_types_mapping =
    line:       'line'
    candles:    'candlestick'
    stockbar:   'ohlc'
    bar:        'column'


make_content = (container) ->
    container.html("<div id=\"chart-period-selector-container\"></div><div id=\"chart-type-selector-container\"></div><div id=\"chart-container\"></div>")    


make_chart_period_selector = (container) ->
    list = $('<ul>')

    for chart_period in chart_periods
        item = $('<li>').html chart_period.title
        item.addClass("selected") if chart_period.selected
        list.append item

    container.append list


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
                    compare: 'percent'
    
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
    xaxis.setExtremes(options.min, options.max, true, false) if options.min? and options.max?
    

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


widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    chart_periods_container     = $('#chart_periods', wrapper)
    chart_types_container       = $('#chart_types', wrapper)
    chart_instruments_container = $('#chart_instruments', wrapper)
    
    current_period  = undefined
    current_type    = undefined
    instruments     = {}
    
    # interface
    
    setPeriod = (period) ->
        item = $("li[data-period=#{period}]", chart_periods_container); return if _.size(item) == 0
    
        item.siblings().removeClass('selected')
        item.addClass('selected')
    
        current_period = period
    

    setType = (type) ->
        item = $("li[data-type=#{type}]", chart_types_container); return if _.size(item) == 0

        item.siblings().removeClass('selected')
        item.addClass('selected')

        current_type = type
    
    toggleInstrument = (param) ->
        item = $("li[data-param=#{param}]", chart_instruments_container); return if _.size(item) == 0
        
        console.log param
        instruments[param] ?= {}
        instruments[param].disabled = !instruments[param].disabled
        
        item.toggleClass('disabled')
        
        console.log instruments
        
    # event observers
    
    # event listeners

    chart_periods_container.on "click", "li:not(.selected)", (event) ->
        setPeriod $(event.currentTarget).data('period')
    
    chart_types_container.on "click", "li:not(.selected)", (event) ->
        setType $(event.currentTarget).data('type')
    
    chart_instruments_container.on "click", "li", (event) ->
        toggleInstrument $(event.currentTarget).data('param')

    # initialization
    
    setPeriod(_.first(period.name for period in chart_periods when period.is_default))

    setType(_.first(type.name for type in chart_types when type.is_default))
    
    $(chart_instruments_container).sortable
        axis: 'x'
        tolerance: 'intersect'

    # returned interface
    
    {
        setPeriod: setPeriod
        setType: setType
    }
    

$.extend scope,
    chart: widget
