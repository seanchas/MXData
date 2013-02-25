##= require kizzy
##= require mx.i18n

#
# Tickers table history by market
#


cache = kizzy('csv-options')


known_data_types = 'csv xml'.split(' ')


make_market_history_url = (engine, market, type, date) ->
    csv_options = Object.keys(fields.mapping).map((key) -> if cache.get(key)? then "#{fields.mapping[key]}=#{encodeURIComponent(cache.get(key))}" else undefined).filter((value) -> !!value).join('&')
    csv_options = if type == 'csv' and csv_options.length > 0 then '&' + csv_options else ''
    "#{mx.url}/iss/history/engines/#{engine}/markets/#{market}/securities.#{type}?date=#{mx.I18n.to_date(date, { format: '%Y-%m-%d' })}&lang=#{mx.I18n.locale}" + csv_options



month_names = 
    ru: [ "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь" ]
    en: [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ]


fields =
    order: ['separator_formats', 'decimal_mark_formats', 'date_formats', 'time_formats']
    mapping:
        separator_formats:      'iss.delimiter'
        decimal_mark_formats:   'iss.dp'
        date_formats:           'iss.df'
        time_formats:           'iss.tf'
    ru:
        separator_formats:      'Разделитель полей'
        decimal_mark_formats:   'Десятичный разделитель'
        date_formats:           'Формат даты'
        time_formats:           'Формат времени'
    en:
        separator_formats:      'Fields separator'
        decimal_mark_formats:   'Decimal mark'
        date_formats:           'Date format'
        time_formats:           'Time format'





make_csv_options_widget = ->
    list = $('<dl>')
        .addClass('csv-options')
    
    fields.order.forEach (field) ->
        $('<dt>')
            .html(fields[mx.I18n.locale][field])
            .appendTo(list)
        
        select = $('<select>')
            .attr('name', field)
        
        mx.I18n.t(['csv', field]).forEach (item) ->
            $('<option>')
                .attr('value', item[1])
                .attr('selected', item[1] == cache.get(field))
                .html(item[0])
                .appendTo(select)
        
        $('<dd>')
            .append(select)
            .appendTo(list)
    
    list.on 'change', 'select', (event) ->
        $('select', list).serializeArray().forEach (item) -> cache.set(item.name, item.value)
    
    list.hide()


toggle = (element) ->
    element.toggle('blind', { direction: 'vertical' }, 100)


# toggle market history panel
$(document).on 'click', '.table_container h4 a.market-history[data-market]', (event) ->
    event.preventDefault()
    
    element             = $(@)
    datepicker_element  = $('.datepicker', element.next('.down-slider'))

    datepicker_element.datepicker({ monthNames: month_names[mx.I18n.locale] }) unless datepicker_element.hasClass('hasDatepicker')
    
    toggle element.next('.down-slider')


# download market history
$(document).on 'click', '.table_container h4 button[data-type]', (event) ->
        el                      = $(@)
        type                    = el.data('type') ; return if known_data_types.indexOf(type) < 0
        [engine, market]        = $('a[data-market]', el.closest('h4')).data('market').split(':')
        date                    = $('.datepicker', el.closest('h4')).datepicker('getDate')
        
        window.open(make_market_history_url(engine, market, type, date))


# toggle market history csv options
$(document).on 'click', '.table_container h4 button.dropdown-toggle', (event) ->
    el          = $(@)
    csv_options = $('.csv-options', el.closest('h4'))
    csv_options = make_csv_options_widget().appendTo(el.closest('.down-slider-content')) if csv_options.length == 0
    
    el.toggleClass('open') ; toggle(csv_options)
