#
# Tickers table history by market
#

$(document).on 'click', 'table.tickers caption a[data-market]', (event) ->
    event.preventDefault()

    element = $(@)

    unless element.data('popover')
        element.popover
            content: 'Content: ' + element.data('market')
            
        element.popover('show')
