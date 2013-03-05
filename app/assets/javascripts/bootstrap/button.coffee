toggle = (button) ->
    button_group = button.closest('[data-toggle=buttons-radio]')
    button_group.find('.active').removeClass('active')
    button.toggleClass('active')


$(document).on 'click.button.data-api', '[data-toggle^=button]', (event) ->
    button = $(event.target)
    button = button.closest('.button') unless button.hasClass('button')
    toggle button
