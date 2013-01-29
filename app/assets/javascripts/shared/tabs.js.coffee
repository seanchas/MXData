##= require jquery


root            = @
root.shared    ?= {}
scope           = root.shared


widget = (container) ->
    container = $(container) ; return if container.length == 0
    
    on_activate     = new $.Callbacks
    
    self = {}
    
    tabs        = $('> ul > li', container) if container
    contents    = $('> div', container) if container
    
    tab = (key) ->
        $(tabs.get().filter((t) -> $(t).data('key') == key)[0])
    
    content = (key) ->
        $(contents.get().filter((c) -> $(c).data('key') == key)[0])
    

    activate = (key) ->
        t = tab(key) ; return if t.length == 0
        
        if t.hasClass('tab') and not t.hasClass('current')
            tabs.not(t).removeClass('current') ; t.addClass('current')
            c = content(key) ; return if c.length == 0
            contents.not(c).hide() ; c.show()

        on_activate.fire(key)
        
        self
    
    
    container.on 'click', '> ul > li > a', (event) ->
        event.preventDefault() ; activate $(@).closest('li').data('key')
    
    $.extend self,
        on_activate:    (callback) ->   on_activate.add(callback)
        activate:       activate
        tab:            tab
        content:        content
    
    self


$.extend scope,
    tabs: widget
