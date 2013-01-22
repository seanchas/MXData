root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined


call_columns    = ['NUMTRADES', 'OPENPOSITION', 'LAST', "TRADEDATETIME", 'LASTTOPREVPRICE', 'BID', 'OFFER', 'THEORPRICE']
key_columns     = ['STRIKE', 'VOLAT']
put_columns     = ['THEORPRICE', 'BID', 'OFFER', 'LAST', "TRADEDATETIME", 'LASTTOPREVPRICE', 'NUMTRADES', 'OPENPOSITION']


iss_date_format = d3.time.format('%Y-%m-%d %H:%M:%S')


i18n_key = 'security_optionsboard'


mx.I18n.add_translations "ru.#{i18n_key}",
    expirations:
        zero:   'дней до исполнения'
        one:    'день до исполнения'
        few:    'дня до исполнения'
        many:   'дней до исполнения'
        other:  'дня до исполнения'
    


prepare_data = (data) ->
    _.reduce(data, ((memo, record) -> (memo[record.STRIKE] ?= {})[record.CONTRACTTYPE] = record ; memo ), {})



calculate_sum = (data, type, column) ->
    _.reduce(data, ((memo, record) -> memo += record[type]?[column] ; memo), 0)


render = (data, columns, container) ->
    container.empty()

    call_trades_sum     = calculate_sum(data, 'C', 'NUMTRADES')
    put_trades_sum      = calculate_sum(data, 'P', 'NUMTRADES')
    call_positions_sum  = calculate_sum(data, 'C', 'OPENPOSITION')
    put_positions_sum   = calculate_sum(data, 'P', 'OPENPOSITION')
    
    _.chain(data).keys().sort((a, b) -> a - b).each((key) -> render_row data[key], columns, container)
    

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


widget = (container, ticker) ->
    container   = $(container) ; return if container.length == 0
    
    deferred    = new $.Deferred
    
    [board, id] = ticker.split(':')
    metadata   ?= mx.data.metadata()
    columns     = undefined
    
    ready       = $.when metadata
    

    reload = ->
        
        # HARDCODED
        options_board = mx.iss.security_optionsboard 'futures', 'forts', id
        
        options_board.then ->
            
            options_board   = options_board.result
            data            = prepare_data options_board.data
            
            render data, columns, $('tbody', container)
            
            _.delay reload, 5 * 1000


    ready.then ->
        
        board = metadata.board board
        
        columns = mx.iss.security_optionsboard_columns 'futures', 'forts'
        
        columns.then ->
            columns = _.reduce(columns.result.data, ((memo, column) -> memo[column.name] = column ; memo), {})
            reload()
        
        deferred.resolve()
    
    
    deferred.promise()



$.extend scope,
    optionsboard: widget
