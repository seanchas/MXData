##= require_self
##= require_tree ./optionsboard


root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined


call_columns    = ['NUMTRADES', 'OPENPOSITION', 'LAST', "TRADEDATETIME", 'LASTTOPREVPRICE', 'BID', 'OFFER', 'THEORPRICE']
key_columns     = ['STRIKE', 'VOLAT']
put_columns     = ['THEORPRICE', 'BID', 'OFFER', 'LAST', "TRADEDATETIME", 'LASTTOPREVPRICE', 'NUMTRADES', 'OPENPOSITION']


iss_date_format = d3.time.format('%Y-%m-%d %H:%M:%S')


prepare_data = (data) ->
    result = {}

    _.each(data['call'],    (record) -> (result[record.STRIKE] ?= {})['C'] = record)
    _.each(data['put'],     (record) -> (result[record.STRIKE] ?= {})['P'] = record)
    
    result



calculate_sum = (data, type, column) ->
    _.reduce(data, ((memo, record) -> memo += record[type]?[column] ; memo), 0)


render = (data, columns, container) ->
    container.empty()

    _.chain(data).keys().sort((a, b) -> a - b).each((key) -> render_row data[key], columns, container)
    
    container
    

render_row = (data, columns, container) ->
    row = $('<tr>')
        .appendTo(container)
    
    render_cells(data.C,            _.map(call_columns, (column) -> columns[column]),   row, 'call')
    render_cells(data.C ? data.P,   _.map(key_columns, (column) -> columns[column]),    row, 'key')
    render_cells(data.P,            _.map(put_columns, (column) -> columns[column]),    row, 'put')
    
    $('tr:nth-child(odd)', container).addClass('odd')
    $('tr:nth-child(even)', container).addClass('even')


render_cells = (data, columns, container, type) ->
    _.each(columns, (column) ->
        
        value = data?[column.name]
        
        value = switch column.type
            when 'date'
                mx.I18n.to_datetime(iss_date_format.parse(value)) if value?
            when 'number'
                scope.utils.number_with_precision(value, { precision: column.precision ? 2 }) if value?
            else
                value
        
        cell = $('<td>')
            .addClass(type)
            .addClass(column.type)
            .html(value ? '&nbsp;')
            .appendTo(container)
    )


widget = (ticker, options = {}) ->
    container               = $(options.container) ; container = undefined if container.length == 0
    expirations_container   = $(options.expirations_container) ; expirations_container = undefined if expirations_container.length == 0
    
    deferred    = new $.Deferred
    
    metadata   ?= mx.data.metadata()
    [board, id] = ticker.split(':')
    columns     = undefined
    
    expiration_chooser = scope.optionsboard_expiration_chooser ticker
    
    ready       = $.when metadata, expiration_chooser
    
    html        = ich.options_board()
    
    render_in_container = -> container.html(html) if container? ; render_in_container = _.once render_in_container    
    
    reload = ->
        
        options_board = mx.iss.security_optionsboard board.engine.name, board.market.name, board.id, id, expiration_chooser.date(), { force: true, expires_in: 20 * 1000 }
        
        options_board.then ->
            
            options_board   = options_board.result
            data            = prepare_data options_board.data
            
            render data, columns, $('tbody', html)
            
            render_in_container()
            
            deferred.resolve()
            
            _.delay reload, 20 * 1000


    ready.then ->
        
        board = metadata.board board
        
        columns = mx.iss.security_optionsboard_columns board.engine.name, board.market.name
        
        columns.then ->
            columns = _.reduce(columns.result.data, ((memo, column) -> memo[column.name] = column ; memo), {})
            reload()
        
        expirations_container.html(expiration_chooser.html()) if expirations_container? > 0
        
        expiration_chooser.on_change reload
        
    
    deferred.promise
        expiration_chooser: -> expiration_chooser
        html:               -> html



$.extend scope,
    optionsboard: widget
