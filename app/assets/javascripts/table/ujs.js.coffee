#
# Tickers table history by market
#

$(document).on 'click', 'table.tickers caption a[data-market]', (event) ->
    event.preventDefault()
    
    element             = $(@)
    datepicker_element  = $('.datepicker', element.next('.down-slider'))

    datepicker_element.datepicker() unless datepicker_element.hasClass('hasDatepicker')
    
    element.next('.down-slider').toggle('blind', { direction: 'vertical' }, 100);
