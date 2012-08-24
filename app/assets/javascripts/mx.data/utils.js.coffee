root    = @
scope   = root['mx']['data']

$       = jQuery



number_with_delimiter = (value, options = {}) ->
    return value unless value? or _.isNumber(value)
    
    delimiter               = options.delimiter ? ' '
    separator               = options.separator ? '.'
    [integer, fractional]   = value.toString().split('.')
    
    integer = integer.replace /(\d)(?=(\d{3})+(?!\d))/g, '$1' + delimiter

    _.compact([integer, fractional]).join(separator)


number_with_precision = (value, options = {}) ->
    return value unless value? or _.isNumber(value)
    
    precision = options.precision ?  2
    
    number_with_delimiter(value.toFixed(precision), options)



prepare_marketdata_record = (record, columns) ->
    return record unless record?
    
    record.precisions   = {}
    record.trends       = {}
    
    default_precision   = record.DECIMALS
    
    for name, value of record
        column = _.find(columns, (column) -> column.name == name) ; continue unless column?
        
        record[name] = switch column.type
            when 'number'
                record.precisions[name] = if !!column.has_percent then 2 else column.precision ? default_precision
                if value? then parseFloat(new Number(value).toFixed(record.precisions[name])) else value
            else
                value
    
    for id, column of columns
        if column.trend_by?
            trending_column = columns[column.trend_by]
            record.trends[column.name] = { value: record[trending_column.name], self: column == trending_column } if trending_column?
    
    record
    

render_marketdata_record_value = (name, record, column) ->

    switch column.type
        when 'number'
            render_marketdata_record_number_value(name, record, column)
        else
            record[name]


render_marketdata_record_number_value = (name, record, column) ->
    value = record[name] ; return value unless value?
    
    value_for_render = number_with_precision(value, { precision: record.precisions[name] })
    
    if !!column.is_signed and value > 0
        value_for_render = '+' + value_for_render
    
    if !!column.has_percent
        value_for_render = value_for_render + '%'
        
    
    value_for_render


$.extend scope,
    utils:
        prepare_marketdata_record: prepare_marketdata_record
        render_marketdata_record_value: render_marketdata_record_value
