root    = @
scope   = root['mx']['data']


$       = jQuery


make_container = (wrapper, market) ->
    container = $("<div>")
        .attr
            "id": "#{market.trade_engine_name}-#{market.market_name}-container"

    title = $("<h4>")
        .html("#{market.trade_engine_title} :: #{market.market_title}")
    
    table = $("<table>")
        .attr
            "id": "#{market.trade_engine_name}-#{market.market_name}-table"
        .html("<thead></thead><tbody></tbody>")
    
    container.append title
    container.append table
    
    container.appendTo wrapper


widget = (wrapper, market_object) ->
    wrapper     = $(wrapper); return if _.size(wrapper) == 0
    
    engine      = market_object.trade_engine_name
    market      = market_object.market_name
    
    container   = make_container(wrapper, market_object)
    table       = $("table", container)
    table_body  = $("tbody", table)
    
    
    securities = []
    
    securityExists = (data) ->
        _.size(security for security in securities when security == "#{data.board}:#{data.param}") > 0

    addSecurity = (data) ->
        securities.push "#{data.board}:#{data.param}"
        
        render()
        
    # render
    
    render = ->
        $.when(
            mx.iss.marketdata_filters(engine, market),
            mx.iss.marketdata_columns(engine, market),
            mx.iss.marketdata(engine, market, securities)
        ).then (filters, columns, data) ->
            console.log filters, columns, data
    

    onSecuritySelected = (event, data) ->
        return unless data.engine == engine and data.market == market
        addSecurity data unless securityExists data
        
    # event observers
    
    $(window).on "security:selected", onSecuritySelected
    
    
    


$.extend scope,
    table: widget
