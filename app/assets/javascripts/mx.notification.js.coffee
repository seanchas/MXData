##= require jquery
##= require underscore
##= require jquery.purr

root    = @
$       = jQuery


handle_table_tickers_messages = true
handle_chart_tickers_messages = true


notification_options =
    fadeInSpeed: 250
    fadeOutSpeed: 250
    removeTimer: 2000


$(window).on 'table:tickers', (event, memo) ->
    return unless handle_table_tickers_messages
    
    action = switch memo.message
        when 'add'
            'добавлен в таблицу'
        when 'remove'
            'удален из таблицы'
        
    notice = ich.notification({ message: "Инструмент #{memo.ticker} #{action}" })
    
    notice.purr(notification_options)


$(window).on 'chart:tickers', (event, memo) ->
    return unless handle_table_tickers_messages
    
    message = switch memo.message
        when 'add'
            "Инструмент #{memo.ticker} добавлен на график"
        when 'remove'
            "Инструмент #{memo.ticker} убран с графика"
        when 'too many tickers'
            "Превышен лимит инструментов на графике — #{memo.count}"
        when 'too little tickers'
            "На графике должен оставаться хотя бы 1 инструмент"
        else
            "Неизвестное сообщение"
        
    notice = ich.notification({ message: message })
    
    notice.purr(notification_options)
