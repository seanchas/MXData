##= require jquery


root            = @
root.shared    ?= {}
scope           = root.shared


build_screen = (html) ->
    $('<div>')
        .addClass('screen')
        .html('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.')
        .appendTo(html)


widget = (container) ->
    container = $(container) ; return if container.length == 0
    
    on_activate = new $.Callbacks
    
    build_screen container
    
    tabs        = $('> ul > li', container)
    contents    = $('> div', container)
    
    
    tab = (key) ->
        $(tabs.get().filter((t) -> $(t).data('key') == key)[0])
    
    content = (key) ->
        $(contents.get().filter((c) -> $(c).data('key') == key)[0])
    

    activate = (key) ->
        t = tab(key) ; return if t.length == 0
        
        if t.hasClass('tab') and not t.hasClass('current')
            tabs.not(t).removeClass('current') ; t.addClass('current')
        
        on_activate.fire(key)
        
        c = content(key) ; return if c.length == 0
        
        contents.not(c).hide() ; c.show()
        
    
    container.on 'click', '> ul > li > a', (event) ->
        event.preventDefault() ; activate $(@).closest('li').data('key')
    

    on_activate:    (callback) ->   on_activate.add(callback)
    activate:       activate
    tab:            tab
    content:        content


$.extend scope,
    tabs: widget
