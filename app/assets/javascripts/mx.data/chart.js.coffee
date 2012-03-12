root    = @
scope   = root['mx']['data']


$       = jQuery


chart_types = ['line', 'candle', 'ohlc']


chart_options =
    
    credits:
        enabled: false
    
    rangeSelector:
        enabled: false
    
    series: [
        {
            name: 'main-line'
        }
        {
            name: 'main-ohlc'
        }
        {
            name: 'main-candle'
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
        # load data
        # mx.cs.highstock securities
        
        # render data
    
    


$.extend scope,
    chart: widget
