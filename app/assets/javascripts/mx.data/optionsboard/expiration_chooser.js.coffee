root    = @
scope   = root['mx']['data']


$       = jQuery


metadata = undefined

iss_date_format = d3.time.format('%Y-%m-%d')


i18n_key = 'security_optionsboard_expirations'

mx.I18n.add_translations "ru.#{i18n_key}",
    expirations:
        one:    'день до исполнения'
        few:    'дня до исполнения'
        many:   'дней до исполнения'
        other:  'дня до исполнения'



render = (dates) ->
    


widget = (ticker, options = {}) ->
    
    deferred    = new $.Deferred
    
    metadata   ?= mx.data.metadata()
    
    [board, id] = ticker.split(':')
    
    dates       = undefined
    
    ready       = $.when metadata
    
    
    reload = ->
        
        expirations = mx.iss.security_optionsboard_expirations board.engine.name, board.market.name, id
        
        expirations.then ->
            
            expirations = expirations.result
            
            dates       = _.map(expirations.data, (date) -> iss_date_format.parse(date.LASTTRADEDATE))
            
            render dates
            
            deferred.resolve() if deferred.state() == 'pending'


    ready.then ->
        
        board = metadata.board board
        
        reload()
        
        

    deferred.promise()


$.extend scope,
    optionsboard_expiration_chooser: widget
