root        = @
scope       = root['mx']['data']


$           = jQuery


metadata    = undefined


default_filter_name     = 'full'
description_filter_name = 'description'
default_precision       = 4


iss_date_format = d3.time.format('%Y-%m-%d')


i18n_key = 'security_info_description'



mx.I18n.add_translations "en.#{i18n_key}",
    security_indices:
        title: 'Inlcuded in indices'
    index_securities:
        title: 'Calculation base'
    date: d3.time.format('%m/%d/%Y')
    face_unit:
        SUR: 'RUR'



mx.I18n.add_translations "ru.#{i18n_key}",
    security_indices:
        title: 'Входит в индексы'
    index_securities:
        title: 'База расчета'
    date: d3.time.format('%d.%m.%Y')
    face_unit:
        SUR: 'RUR'



prepare_render = ->
    $('<table>')
        .html('<thead></thead><tbody></tbody><tfoot></tfoot>')


render_security = (data, html, options = {}) ->
    table_head = $('thead', html)
    
    _.chain(data).filter((record) -> !record.is_hidden).each((record) -> render_security_table_row record, table_head, options)
    
    html


render_security_table_row = (record, html, options) ->
    row = $('<tr>')
        .appendTo(html)
    
    $('<th>')
        .html(record.title)
        .appendTo(row)
    
    value = record.value
    
    value = mx.I18n.translate([i18n_key, 'face_unit', value], { default: value }) if record.name == 'FACEUNIT'
    
    value = switch record.type
        when 'number'
            scope.utils.number_with_precision(+ value, { precision: record.precision ? options.precision })
        when 'date'
            mx.I18n.translate([i18n_key, 'date']) iss_date_format.parse(value)
        else
            value
    
    $('<td>')
        .html(value)
        .appendTo(row)
    
    html


render_security_marketdata = (data, html, options = {}) ->
    table_body = $('tbody', html)
    
    _.each(options.columns, (column) -> render_security_marketdata_table_row data, column, html, options)
    
    html


render_security_marketdata_table_row = (data, column, html, options) ->
    row = $('<tr>')
        .appendTo(html)
    
    $('<th>')
        .html(column.title)
        .appendTo(row)
    
    $('<td>')
        .html(data[column.name])
        .appendTo(row)
    
    html


render_security_indices = (data, html) ->
    table_foot = $('tfoot', html)
    
    row = $('<tr>')
        .appendTo(table_foot)
    
    $('<th>')
        .html(mx.I18n.translate([i18n_key, 'security_indices.title']))
        .appendTo(row)
    
    $('<td>')
        .html(_.pluck(data, 'SHORTNAME').join(', '))
        .appendTo(row)
    
    html


render_index_securities = (data, html) ->
    table_foot = $('tfoot', html)
    
    row = $('<tr>')
        .appendTo(table_foot)
    
    $('<th>')
        .html(mx.I18n.translate([i18n_key, 'index_securities.title']))
        .appendTo(row)
    
    $('<td>')
        .html(_.pluck(data, 'shortnames').join(', '))
        .appendTo(row)
    
    html


widget = (ticker) ->
    
    deferred = new $.Deferred
    
    access      = undefined
    html        = undefined
    error       = undefined
    [board, id] = ticker.split(':')
    
    
    metadata    ?= mx.data.metadata()
    columns     = undefined
    
    
    ready   = $.when metadata
    
    
    reload = ->
        security            = mx.iss.security id
        security_marketdata = mx.iss.security_marketdata board.engine.name, board.market.name, board.id, id
        security_indices    = mx.iss.security_indices id
        index_securities    = mx.iss.index_securities board.engine.name, board.market.name, id
        
        $.when(security, security_marketdata, security_indices, index_securities).then ->
            
            html                = undefined

            security            = security.result
            security_marketdata = security_marketdata.result
            security_indices    = security_indices.result
            index_securities    = index_securities.result
            
            html                = prepare_render()
            
            precision           = security_marketdata.data.security?.DECIMALS ? default_precision
            
            render_security(security.data.description, html, { precision: precision })  unless  security.error?
            
            security_columns    = _.chain(security.data.description).filter((record) -> !record.is_hidden).pluck('name').value()
            
            render_security_marketdata(security_marketdata.data.security, html, {
                precision:  precision
                columns:    _.filter(columns, (column) -> !_.include(security_columns, column.name))
            })  unless  security_marketdata.error?

            render_security_indices(security_indices.data, html)                        unless  security_indices.error? or security_indices.data.length == 0
            render_index_securities(index_securities.data, html)                        unless  index_securities.error? or index_securities.data.length == 0

            $(window).trigger "security-info:description:loaded:#{ticker}"
        
    
    
    ready.then ->
        
        board = metadata.board(board)
        
        columns = mx.iss.security_marketdata_columns(board.engine.name, board.market.name)
        filters = mx.iss.security_marketdata_columns_filters(board.engine.name, board.market.name)
        
        $.when(columns, filters).then ->
            
            filters = _.reduce(filters.result.data, ((memo, record) -> (memo[record.filter_name] ?= []).push(record) ; memo), {})

            columns = _.reduce(columns.result.data.security, ((memo, record) -> memo[record.name] = record ; memo), {})

            columns = _.reduce(filters[description_filter_name] ? filters[default_filter_name], ((memo, record) -> memo.push(columns[record.name]) if columns[record.name]? and !columns[record.name].is_hidden ; memo ), [])
            
            reload()
        
            deferred.resolve()
    
    
    deferred.promise
        access: -> access
        html:   -> html
        error:  -> error



$.extend scope,
    security_info_description: widget
