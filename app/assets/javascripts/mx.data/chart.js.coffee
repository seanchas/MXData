root    = @
scope   = root['mx']['data']


$       = jQuery


chart_types = ['line', 'candles', 'stockbar']


chart_types_titles =
    line:       'Линия'
    candles:    'Свечи'
    stockbar:   'Бары'


chart_types_mapping =
    line:       'line'
    candles:    'candlestick'
    stockbar:   'ohlc'


make_content = (container) ->
    container.html("<div id=\"chart-type-selector-container\"></div><div id=\"chart-container\"></div>")    


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
    
    credits:
        enabled: false
    
    rangeSelector:
        enabled: false
    
    plotOptions:
        ohlc:
            lineWidth: 2
        series:
            gapSize: 60


# default series options

default_series_options =
    dataGrouping:
        smoothed: true


# default x axis options

default_xaxis_options =
    id: null


# default y axis options

default_yaxis_options =
    id: null


_make_chart = (container, data, options = {}) ->
    chart_options = $.extend true, {}, default_chart_options
    
    series  = []
    xAxis   = []
    yAxis   = []
    
    
    xAxis.push $.extend true, {}, default_xaxis_options

    yAxis.push $.extend true, {}, default_yaxis_options

    yAxis.push $.extend true, {}, default_yaxis_options,
        opposite: true


    data_size = _.size data
    
    
    if data_size > 2
        $.extend true, chart_options,
            plotOptions:
                series:
                    compare: 'percent'
    
    for serie, index in data
        serie_options = $.extend true, {}, default_series_options

        $.extend serie_options,
            type:   chart_types_mapping[serie.type]
            data:   serie.data
            yAxis:  if index == 1 and data_size == 2 then 1 else 0
    
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


widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    securities  = []
    
    make_content wrapper

    make_chart_type_selector $('#chart-type-selector-container', wrapper)

    chart_container = $('#chart-container', wrapper)
    chart           = _make_chart chart_container, [{ data: [] }]
    
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
            
            chart = _make_chart chart_container, candles, { chart: chart, min: min, max: max }
                    
    
    addSecurity('stock:shares:EQNE:GAZP')
    addSecurity('stock:index:SNDX:MICEXINDEXCF')
    addSecurity('stock:index:SNDX:MICEX10INDEX')
    addSecurity('stock:index:SNDX:MICEXO&G')
    addSecurity('stock:shares:EQBR:AFLT')
    
    # event observers
    
    onChartTypeSelectorChange = (event) ->
        setChartType chart_type_selector.val()

    # event listeners
    
    chart_type_selector.on "change", onChartTypeSelectorChange
    
    


$.extend scope,
    chart: widget
