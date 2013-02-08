mx.I18n.add_translations 'en',
    number:
        format:
            separator: '.'
            delimiter: ','
    date:
        formats:
            default: '%m/%d/%Y'
    time:
        formats:
            default: '%H:%M:%S'
    csv:
        separator_formats:      [ [';', ';'], [',', ','] ]
        decimal_mark_formats:   [ [',', 'comma'], ['.', 'point'] ]
        date_formats:           [ ['yyyymmdd', '%Y%m%d'], ['yymmdd', '%y%m%d'], ['ddmmyyyy', '%d%m%Y'], ['ddmmyy', '%d%m%y'], ['dd.mm.yyyy', '%d.%m.%Y'], ['dd.mm.yy', '%d.%m.%y'], ['dd/mm/yyyy', '%d/%m/%Y'], ['dd/mm/yy', '%d/%m/%y'], ['mm/dd/yyyy', '%m/%d/%Y'], ['mm/dd/yy', '%m/%d/%y'] ]
        time_formats:           [ ['hhmmss', '%H%M%S'], ['hhmm', '%H%M'], ['hh:mm:ss', '%H:%M:%S'], ['hh:mm', '%H:%M'] ]


mx.I18n.add_translations 'ru',
    number:
        formats:
            separator: ','
            delimiter: ' '
    date:
        formats:
            default: '%d.%m.%Y'
    time:
        formats:
            default: '%H:%M:%S'
    csv:
        separator_formats:      [ [';', ';'], [',', ','] ]
        decimal_mark_formats:   [ [',', 'comma'], ['.', 'point'] ]
        date_formats:           [ ['ггггммдд', '%Y%m%d'], ['ггммдд', '%y%m%d'], ['ддммгггг', '%d%m%Y'], ['ддммгг', '%d%m%y'], ['дд.мм.гггг', '%d.%m.%Y'], ['дд.мм.гг', '%d.%m.%y'], ['дд/мм/гггг', '%d/%m/%Y'], ['дд/мм/гг', '%d/%m/%y'], ['мм/дд/гггг', '%m/%d/%Y'], ['мм/дд/гг', '%m/%d/%y'] ]
        time_formats:           [ ['ччммсс', '%H%M%S'], ['ччмм', '%H%M'], ['чч:мм:сс', '%H:%M:%S'], ['чч:мм', '%H:%M'] ]
