global_selector = '[data-toggle=dropdown]'

clear_menus = ->
    $(global_selector).each -> get_parent($(@)).removeClass('open')
    

toggle = ->
    el          = $(@) ; return if el.is('.disabled, :disabled')
    pa          = get_parent(el)
    is_active   = pa.hasClass('open')

    clear_menus()
    
    pa.toggleClass('open') unless is_active
    
    if is_active then el.blur() else el.focus()
    
    false


keydown = (e) ->
    return unless e.keyCode == 27
    
    e.preventDefault()
    e.stopPropagation()
    
    el          = $(@) ; return if el.is('.disabled, :disabled')
    pa          = get_parent(el)
    is_active   = pa.hasClass('open')
    
    if !is_active or (is_active and e.keyCode == 27)
        pa.find(global_selector).focus() if e.which == 27
        return el.click()

    return
    

get_parent = (el) ->
    selector = el.attr('data-target')
    
    unless selector?
        selector = el.attr('href')
        selector = selector and /#/.test(selector) and selector.replace(/.*(?=#[^\s]*$)/, '')
    
    pa = selector and $(selector)

    unless pa? and pa.length
        pa = el.parent()
    
    pa


$(document)
    .on('click.dropdown', clear_menus)
    .on('click.dropdown', global_selector, toggle)
    .on('keydown.dropdown', global_selector, keydown)
