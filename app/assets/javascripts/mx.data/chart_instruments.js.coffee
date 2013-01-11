root    = @
scope   = root['mx']['data']


$       = jQuery


max_instruments = 5


bootstrap_data  = mx.iss.bootstrap()
bootstrap_keys  = ['indices', 'currencies']


make_instruments_wrapper = (wrapper) ->
    container = $('<ul>').attr('id', 'chart_instruments')
    
    wrapper.html container
    
    container


make_instrument_view = (instrument, index, size) ->
    view = $('<li>')
        .attr({ 'data-param': instrument.id })
        .css('background-color', scope.background_colors[index])
        .html(instrument.title || instrument.id)
        .toggleClass('disabled', !!instrument.disabled)
    
    if instrument.failure?
        view.prepend $('<span>').addClass('failure').html('!')
        view.attr('title', instrument.failure)
    
    if size > 1
        view
            .append($('<span>').addClass('remove'))
            .addClass('removeable')
    
    view


instruments_from_bootstrap = _.once ->
    _.map bootstrap_keys, (key) -> instrument = _.first bootstrap_data[key] ; { id: instrument['SECID'], board: instrument['BOARDID'], title: instrument['SHORTNAME'] }


widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0

    deferred            = new $.Deferred
    
    instruments_wrapper = undefined
    

    instruments         = []
    instruments_changed = true


    ready_for_render    = $.when true

    sort_in_progress    = false
    
    
    render = ->
        return if sort_in_progress
        instruments_wrapper.empty()
        instruments_wrapper.append make_instrument_view instrument, index, _.size(instruments) for instrument, index in instruments
    

    update = (message, data) ->
        instruments_changed = true
        scope.caches.chart_instruments instruments
        
        render()
        
        broadcast message, data
        

    broadcast = (message, ticker) ->
        return unless deferred.state() == 'resolved'
        return unless instruments_changed
        
        instruments_changed = false
        
        $(window).trigger 'chart:instruments:changed', [instruments, message]
        
        if (message == 'add' or message == 'remove')
            $(window).trigger 'chart:tickers', { ticker: [ticker.board, ticker.id].join(':'), message: message }
    
    
    add_cached = ->
        add instrument for instrument in scope.caches.chart_instruments() || []
        
    
    add = (data) ->
        if _.size(instruments) >= max_instruments
            return $(window).trigger 'chart:tickers', { message: 'too many tickers', count: max_instruments }
        
        if _.isString(data)
            [board, id] = data.split(':')
            data = { board: board, id: id }
        
        return if _.size(instrument for instrument in instruments when instrument.id == data.id)
        
        instruments.push data
        
        update 'add', instrument
    
    del = (data) ->
        remove _.last(data.split(':'))
    

    remove = (param) ->
        if _.size(instruments) == 1
            return $(window).trigger 'chart:tickers', { message: 'too little tickers' }
            
        
        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?
        
        instruments = _.without instruments, instrument
        
        _.first(instruments).disabled = false if should_be_enabled()
        
        update 'remove', instrument
        
        

    toggle_state = (param) ->
        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?
        
        instrument.disabled = !instrument.disabled
        
        instrument.disabled = false if should_be_enabled()

        update 'toggle state'
    
    reorder = ->
        params      = $('li', @).map -> $(@).data('param')
        instruments = _.sortBy instruments, (instrument) ->_.indexOf params, instrument.id
        sort_in_progress = false

        update 'reorder'


    should_be_enabled = ->
        _.size(instrument for instrument in instruments when !instrument.disabled) == 0
    
    
    ready_for_render.then ->
        instruments_wrapper = make_instruments_wrapper wrapper
        
        add_cached()
        
        instruments_wrapper.on 'click', 'li', (event) ->
            toggle_state $(@).data('param')

        instruments_wrapper.on 'click', 'li span', (event) ->
            remove $(@).closest('li').data('param')
        
        $(window).on 'security:to:chart', (event, data) -> add data
        $(window).on 'security:from:chart', (event, data) -> del data
        
        $(window).on 'chart:render:complete', (event) -> render()
        
        $(instruments_wrapper).sortable
            axis: 'x'
            start:  -> sort_in_progress = true
            update: reorder

        deferred.resolve()
        
        broadcast('init')
    

    deferred.promise({ data: -> instruments })
    


$.extend scope,
    chart_instruments: widget
