root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined

iss_date_format = d3.time.format('%Y-%m-%d')

milliseconds_in_day = 24 * 60 * 60 * 1000


i18n_key = 'security_optionsboard_expirations'

mx.I18n.add_translations "ru.#{i18n_key}",
    title: 'До исполнения'
    expirations:
        one:    '{{count}} день'
        few:    '{{count}} дня'
        many:   '{{count}} дней'
        other:  '{{count}} дня'

mx.I18n.add_translations "en.#{i18n_key}",
    title: 'Expiration in'
    expirations:
        one:    '{{count}} day'
        other:  '{{count}} days'



render = (dates) ->
    now     = new Date
    days    = _.map(dates, (date) -> Math.ceil((iss_date_format.parse(date) - now) / milliseconds_in_day))
    
    
    html = $('<span>')
        .addClass('expirations_chooser')
        .toggleClass('inactive', days.length == 1)
    
    $('<span>')
        .addClass('title')
        .html(mx.I18n.t([i18n_key, 'title']))
        .appendTo(html)
    
    _.each(days, (day, index) ->
        $('<a>')
            .data('days', day)
            .data('date', dates[index])
            .addClass('day')
            .toggleClass('active', day == days[0])
            .attr('href', '#')
            .html(mx.I18n.t([i18n_key, 'expirations'], { count: day }))
            .appendTo(html)
            .wrap($('<span>').addClass('day'))
        
    )
    
    html


toggle_active_link = (link, html) ->
    link    = $(link)
    links   = $('a.day', html).not(link)

    links.removeClass('active')
    link.addClass('active')
    

widget = (ticker, options = {}) ->
    
    deferred    = new $.Deferred
    
    on_change_callbacks   = new $.Callbacks
    
    metadata   ?= mx.data.metadata()
    
    [board, id] = ticker.split(':')
    
    ready       = $.when metadata
    
    dates       = undefined
    html        = undefined
    date        = undefined
    
    
    reload = ->
        
        expirations = mx.iss.security_optionsboard_expirations board.engine.name, board.market.name, board.id, id
        
        expirations.then ->
            
            expirations = expirations.result
            
            dates       = _.map(expirations.data, (date) -> date.LASTTRADEDATE)
            
            html        = render(dates)
            date        = $('a.day.active', html).data('date')
            
            if deferred.state() == 'pending'

                html.on 'click', 'a.day', (event) ->
                    event.preventDefault() ; link = $(@)
                    
                    unless link.hasClass('active')

                        toggle_active_link(link, html)

                        date = link.data('date')

                        on_change_callbacks.fire()

                deferred.resolve()


    ready.then ->
        
        board = metadata.board board
        
        reload()
        
        

    deferred.promise
        html:                   -> html
        date:                   -> date
        on_change: (callback)   -> on_change_callbacks.add(callback)


$.extend scope,
    optionsboard_expiration_chooser: widget
