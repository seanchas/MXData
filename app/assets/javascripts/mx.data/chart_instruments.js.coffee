root    = @
scope   = root['mx']['data']


$       = jQuery


max_instruments = 5


metadata = undefined


make_instruments_wrapper = (wrapper) ->
    container = $('<ul>').attr('id', 'chart_instruments')
    
    wrapper.html container
    
    container


make_instrument_view = (instrument, index, size) ->
    view = $('<li>')
        .attr({ 'data-param': [instrument.board, instrument.id].join(':') })
        .css('background-color', scope.background_colors[index])
        .html(instrument.id + ' : ' + metadata.board(instrument.board).boardgroup.title)
        .toggleClass('disabled', !!instrument.disabled)
    
    if instrument.failure?
        view.prepend $('<span>').addClass('failure').html('!')
        view.attr('title', instrument.failure)
    
    if size > 1
        view
            .append($('<span>').addClass('remove'))
            .addClass('removeable')
    
    view


widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0

    deferred            = new $.Deferred
    
    instruments_wrapper = undefined
    

    instruments         = []
    instruments_changed = true
    
    
    metadata           ?= mx.data.metadata()


    ready_for_render    = $.when metadata

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
        
        board = metadata.board(data.board)
        
        present = instruments.filter (instrument) ->
            metadata.board(instrument.board).market.name == board.market.name and instrument.id == data.id
        
        return if present.length > 0
        
        instruments.push data
        
        update 'add', data
    
    del = (data) ->
        remove data


    remove = (ticker) ->
        
        if _.size(instruments) == 1
            return $(window).trigger 'chart:tickers', { message: 'too little tickers' }
        
        ticker = do -> [board, id] = ticker.split(':') ; board = metadata.board(board) ; [board, id]
        
        instrument = _.filter(instruments, (instrument) -> board = metadata.board(instrument.board) ; instrument.id == ticker[1] and board.market.name == ticker[0].market.name)[0]
        
        if instrument
            instruments = _.without instruments, instrument
            update 'remove', instrument
        
        _.first(instruments).disabled = false if should_be_enabled()
        

    toggle_state = (param) ->
        [board, id] = param.split(':') ; board = metadata.board(board)
        instrument = _.first(instrument for instrument in instruments when instrument.id == id and metadata.board(instrument.board).market.name == board.market.name)
        return unless instrument?
        
        instrument.disabled = !instrument.disabled
        
        instrument.disabled = false if should_be_enabled()

        update 'toggle state'
    
    reorder = ->
        params      = $('li', @).map(-> $(@).data('param')).get()
        
        instruments = _.sortBy instruments, (instrument) ->_.indexOf params, [instrument.board, instrument.id].join(':')
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
    

    deferred.promise({ data: -> instruments.map((i) -> return { id: [i.board, i.id].join(':'), failure: i.failure })})
    


$.extend scope,
    chart_instruments: widget
