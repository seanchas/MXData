##= require jquery
##= require mx.i18n


root            = @
root.shared    ?= {}
scope           = root.shared

links   = ['login',     'registration', 'user']
sites   = ['passport',  'services',     'logout']

localized_links =
    ru:
        login:
            title:  'Вход'
            href:   'http://passport.beta.micex.ru/login?return_to=' + encodeURIComponent(window.location.href)
        registration:
            title:  'Регистрация'
            href:   'http://passport.beta.micex.ru/registration'
        user:
            title:  ''
            href:   '#'
    en:
        login:
            title:  'Login'
            href:   'http://passport.beta.micex.ru/en/login?return_to=' + encodeURIComponent(window.location.href)
        registration:
            title:  'Registration'
            href:   'http://passport.beta.micex.ru/en/registration'
        user:
            title: ''
            href: '#'

localized_sites = 
    ru:
        passport:
            title:  'Настройки'
            href:   'http://passport.beta.micex.ru/profile'
        services:
            title:  'Управление платными услугами'
            href:   'http://services.beta.micex.ru/requisite'
        logout:
            title:  'Выход из системы'
            href:   'http://passport.beta.micex.ru/logout?return_to=' + encodeURIComponent(window.location.href)
    en:
        passport:
            title:  'Settings'
            href:   'http://passport.beta.micex.ru/en/profile'
        services:
            title:  'Paid services management'
            href:   'http://services.beta.micex.ru/en/requisite'
        logout:
            title:  'Logout'
            href:   'http://passport.beta.micex.ru/en/logout?return_to=' + encodeURIComponent(window.location.href)



cache       = kizzy('shared:user')

unless String.prototype.trimRight
    String.prototype.trimRight = -> @replace(/\s+$/, '')


t = (c) -> if c.toUpperCase() != c.toLowerCase() then 'A' else ' '


prune = (string, length, spacer) ->
    return string unless string?
    
    length = ~~length
    spacer = '...' unless spacer?
    
    return string if string.length <= length
    
    template = string.slice(0, length + 1).replace(/.(?=\W*\w*$)/g, t)
    
    template = if template.slice(template.length - 2).match(/\w\w/)
        template.replace(/\s+\S+$/, '')
    else
        template.slice(0, template.length - 1).trimRight()
    
    if (template + spacer).length > string.length then string else string.slice(0, template.length) + spacer


fetch = ->
    deferred = new $.Deferred
    
    result = {}
    
    $.ajax
        url: if $.browser.msie? then '/cu' else 'http://www.beta.micex.ru/cu'
        dataType: 'json'
        xhrFields:
            withCredentials: true
    .done (json) ->
        result.data     = json
        result.error    = false
    .fail (xhr, error) ->
        result.error    = true
    .always ->
        deferred.resolve(result)
    
    deferred.promise
        result: result



full_name = (data) ->
    [data.last_name, data.first_name, data.middle_name].join(' ').trim()

full_name_or_nickname = (data) ->
    full_name(data) or data.nickname


render_links = (container) ->
    list = $('<ul>')
        .addClass('auth_user_links')
        .appendTo(container)
    
    links.forEach (link) ->
        item = $('<li>')
            .addClass(link)
            .appendTo(list)
            .hide()
        
        link_data = localized_links[mx.I18n.locale][link]
        
        $('<a>')
            .attr('href', link_data.href)
            .html(link_data.title)
            .appendTo(item)
        
    $('li.user a', list).html(cache.get('name'))
    
    list
    

render_sites = (id, container) ->
    html = $('<div>')
        .attr('id', id)
        .addClass('auth_sites_links')
        .appendTo(container)
        .hide()
    
    list = $('<ul>')
        .appendTo(html)
    
    sites.forEach (site) ->
        
        item = $('<li>')
            .addClass(site)
            .appendTo(list)
        
        site_data = localized_sites[mx.I18n.locale][site]
        
        $('<a>')
            .attr('href', site_data.href)
            .html(site_data.title)
            .appendTo(item)
    
    html


done = (user_data, container) ->
    cache.set('name', full_name_or_nickname(user_data))
    
    $('li.user a', container).html(prune(cache.get('name'), 32))
    
    $('li.login, li.registration', container).hide()
    $('li.user', container).show()


fail = (container) ->
    $('li.login, li.registration', container).show()
    $('li.user', container).hide()
    


toggle_sites = (sites, links) ->
    
    if sites.is(':hidden')

        links_offset    = links.offset()
        links_width     = links.outerWidth()
        links_height    = links.outerHeight()
    
        sites.show()
    
        sites_width     = sites.innerWidth()
        sites_height    = sites.outerHeight()
    
        sites.offset
            top:  links_offset.top + links_height 
            left: links_offset.left + links_width - sites_width
        
        sites.hide()
    
    sites.toggle()



widget = (container) ->
    
    container = $(container) ; return if container.length == 0


    links = render_links container

    sites = render_sites container.attr('id') + '_sites_links', $('body')


    reload = ->
        user = fetch()
    
        user.then ->

            user = user.result
        
            if user.error
                fail container
            else
                done user.data, container
            

    container.on 'click', 'li.user a', (event) ->
        event.preventDefault() ; event.stopPropagation()
        
        toggle_sites(sites, links)
    
    $(window).on 'click', -> sites.hide() if sites.is(':visible')
        
    

    reload()


$.extend scope,
    user: widget
