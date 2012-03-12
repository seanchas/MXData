root    = @
scope   = root['mx']['data']


$       = jQuery


chart_types = ['candles', 'line', 'stockbar']


chart_options =
    
    credits:
        enabled: false
    
    rangeSelector:
        enabled: false
    
    series: [
        {
            id: 'main-line'
            type: 'line'
        }
        {
            id: 'main-stockbar'
            type: 'ohlc'
        }
        {
            id: 'main-candles'
            type: 'candlestick'
        }
        
    ]


make_chart = (container) ->
    new Highcharts.StockChart(
        $.extend(
            true,
            {},
            chart_options,
            chart:
                renderTo: container[0]
        )
    )


widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    securities  = []

    chart       = make_chart wrapper
    chart_type  = _.first chart_types
    
    # interface
    
    is_security_included = (param) ->
        _.include securities, param

    addSecurity = (param) ->
        included = is_security_included param
        securities.push param unless included
        refresh()
    
    removeSecurity = (param) ->
        included = is_security_included param
        securities = _.without securities, param if included
    
    # refresh
    
    refresh = ->
        console.log "asd"
        
        chart.showLoading()
        
        console.log chart_type
        
        console.log "asd"
        
        mx.cs.highstock(securities, { type: chart_type }).then (json) ->
            [candles, volumes] = json
            
            candle = _.first(candles)
            
            for candle_type in chart_types
                series = chart.get("main-#{chart_type}")

                if candle_type == candle.type
                    series.setData(candle.data, false)
                    series.show()
                else
                    series.hide()
            
            chart.redraw()
            chart.hideLoading()
                    
    
    addSecurity('stock:index:SNDX:MICEXINDEXCF')
    
    


$.extend scope,
    chart: widget
