root                = @

root['mx']         ?= {}
root['mx'].I18n    ?= {}

i18n                = root['mx'].I18n


i18n.add_translations 'ru',
    date:
        day_names: ['воскресение', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота']

i18n.add_translations 'en',
    date:
        day_names: ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']


localize = ->
    options = if arguments.length > 1 and $.isPlainObject(arguments[arguments.length - 1]) then arguments[arguments.length - 1] else {}
    value   = arguments[0]
    
    

# to number
to_number = (value, options = {}) ->


# to percentage
to_percentage = (value, options = {}) ->


# to date
to_date = (value, options = {}) ->
    to_datetime(value, $.extend({ format: i18n.translate('date.formats.default') }, options))


# to time
to_time = (value, options = {}) ->
    to_datetime(value, $.extend({ format: i18n.translate('time.formats.default') }, options))


# to datetime
to_datetime = (value, options = {}) ->
    return value if $.type(value) != 'date'
    
    options = $.extend
        format: [i18n.translate('date.formats.default', { locale: options.locale }), i18n.translate('time.formats.default', { locale: options.locale })].join(' ')
    , options
    

    replace_datetime_format_token(options.format, value, options)
    

replace_datetime_format_token = (format, value, options) ->
    index = format.indexOf('%')
        
    return format if index == -1
    
    [before, after] = [format.slice(0, index), format.slice(index + 1)]
    
    part    = ''
    padding = '0'
    
    if datetime_format_pads[after.charAt(0)]?
        padding = datetime_format_pads[after.charAt(0)]
        after   = after.slice(1)
    
    if datetime_formats[after.charAt(0)]
        part    = datetime_formats[after.charAt(0)](value, padding, options)
        after   = after.slice(1)
    
    [before, part, replace_datetime_format_token(after, value, options)].join('')
    
    


datetime_format_pads =
    '-': ''
    '_': ' '
    '0': '0'


datetime_format_pad = (v, f, n) -> (new Array(n + 1).join(f) + v).slice(-n)


datetime_formats =
    'A': (v, p) -> i18n.translate('date.day_names')[v.getDay()]
    'd': (v, p) -> datetime_format_pad(v.getDate(),         p, 2)
    'H': (v, p) -> datetime_format_pad(v.getHours(),        p, 2)
    'm': (v, p) -> datetime_format_pad(v.getMonth() + 1,    p, 2)
    'M': (v, p) -> datetime_format_pad(v.getMinutes(),      p, 2)
    'S': (v, p) -> datetime_format_pad(v.getSeconds(),      p, 2)
    'Y': (v, p) -> datetime_format_pad(v.getFullYear(),     p, 4)
    '%':        -> '%'


$.extend i18n,
    localize:       localize
    l:              localize
    to_number:      to_number
    to_percentage:  to_percentage
    to_date:        to_date
    to_time:        to_time
    to_datetime:    to_datetime
