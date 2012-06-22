root    = @
scope   = root['mx']['data']


$       = jQuery

cache = kizzy('data.chart.instruments')


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
        .css('color', scope.colors[index])
        .html(instrument.title)
        .toggleClass('disabled', !!instrument.disabled)
    
    if size > 1
        view
            .append($('<span>'))
            .addClass('removeable')
    
    view


instruments_from_bootstrap = _.once ->
    _.map bootstrap_keys, (key) -> instrument = _.first bootstrap_data[key] ; { id: instrument['SECID'], board: instrument['BOARDID'], title: instrument['SHORTNAME'] }


widget = (wrapper) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0

    deferred            = new $.Deferred
    cache_key           = ''
    
    instruments_wrapper = undefined
    

    instruments         = []
    instruments_changed = true


    ready_for_render    = $.when bootstrap_data
    
    
    render = ->
        instruments_wrapper.empty()
        instruments_wrapper.append make_instrument_view instrument, index, _.size(instruments) for instrument, index in instruments
    

    update = (message) ->
        instruments_changed = true
        cache.set cache_key, instruments
        
        render()
        
        broadcast message


    broadcast = (message) ->
        return unless deferred.state() == 'resolved'
        return unless instruments_changed
        
        instruments_changed = false
        
        $(window).trigger 'chart:instruments:changed', [instruments, message]
    
    
    add_cached = ->
        add instrument for instrument in cache.get(cache_key, instruments) ? instruments_from_bootstrap()
        
    
    add = (data) ->
        return if _.size(instruments) >= max_instruments
        return if _.size(instrument for instrument in instruments when instrument.id == data.id)
        
        instruments.push data
        
        update 'add'
    

    remove = (param) ->
        return if _.size(instruments) == 1
        
        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?
        
        instruments = _.without instruments, instrument
        
        _.first(instruments).disabled = false if should_be_enabled()
        
        update 'remove'
        
        

    toggle_state = (param) ->
        instrument = _.first(instrument for instrument in instruments when instrument.id == param)
        return unless instrument?
        
        instrument.disabled = !instrument.disabled
        
        instrument.disabled = false if should_be_enabled()

        update 'toggle state'
    
    reorder = ->
        params      = $('li', @).map -> $(@).data('param')
        instruments = _.sortBy instruments, (instrument) ->_.indexOf params, instrument.id

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
        
        $(instruments_wrapper).sortable
            axis: 'x'
            update: reorder

        deferred.resolve()
    

    deferred.promise({ data: -> instruments })
    


$.extend scope,
    chart_instruments: widget