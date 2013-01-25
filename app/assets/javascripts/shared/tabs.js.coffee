##= require jquery


root            = @
root.shared    ?= {}
scope           = root.shared


build_screen = (html) ->
    $('<div>')
        .addClass('screen')
        .html('Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.')
        .appendTo(html)


activate_tab = (tab, tabs) ->
    tabs.not(tab).removeClass('current') ; tab.addClass('current')


widget = (container) ->
    container = $(container) ; return if container.length == 0
    
    build_screen container
    
    tabs    = $('> ul > li', container)
    
    container.on 'click', '> ul > li > a', (event) ->
        event.preventDefault()

        tab = $(@).closest('li')
        
        activate_tab(tab, tabs) if tab.hasClass('tab')


$.extend scope,
    tabs: widget
