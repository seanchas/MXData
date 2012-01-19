root    = @
scope   = root['mx']['data']
$       = jQuery

f = (v) -> if v >= 10 then v else "0" + v

l = (date) -> "#{f(date.getDate())}.#{f(date.getMonth() + 1)}.#{f(date.getFullYear())}"


months = [
    "Янв"
    "Фев"
    "Мар"
    "Апр"
    "Май"
    "Июн"
    "Июл"
    "Авг"
    "Сен"
    "Окт"
    "Ноя"
    "Дек"
]


weekdays = [
    "Вс"
    "Пн"
    "Вт"
    "Ср"
    "Чт"
    "Пт"
    "Сб"
]


day_in_millis = 24 * 60 * 60 * 1000


first_day_of_month = (date) ->
    new_date = new Date(date)
    new_date.setDate(1)
    new_date

last_day_of_month = (date) ->
    new_date = new Date(date)
    new_date.setMonth(date.getMonth() + 1)
    new_date.setDate(0)
    new_date


class MonthWidget
    constructor: (@target, @date) ->
        @render()
    
    render: ->
        @month = $("<table>").addClass("month").html("<thead></thead><tbody></tbody>")
        
        table_head = $("thead", @month)
        table_body = $("tbody", @month)
        
        table_head.append($("<tr>").append($("<th>").attr("colspan", 7).html(months[@date.getMonth()] + ' ' + @date.getFullYear())))
        weekdays_row = table_head.append($("<tr>"))
        weekdays_row.append $("<td>").html(weekdays[i]) for i in [0..6]
        
        offset = @calculate_offset()
        length = @calculate_length()
        
        cursor = first_day_of_month(@date).getTime() - offset * day_in_millis
        
        _month = @date.getMonth()
        
        for i in [0...Math.ceil((offset + length) / 7)]
            row = $("<tr>")
            
            for j in [0..6]
                date = new Date(cursor)
                
                row.append $("<td>").html(if date.getMonth() == _month then f(date.getDate()) else "&nbsp;")
                
                cursor += day_in_millis
            
            table_body.append(row)
        
        @target.after @month
    
    calculate_offset: ->
        first_day_of_month(@date).getDay()
    
    calculate_length: ->
        last_day_of_month(@date).getDate()


class YearWidget

    constructor: (@target, @date) ->
        @render()
        @month_widget = new MonthWidget(@year, date)
    
    render: ->
        @year = $("<ul>").addClass("year")
        
        @months = for i in [-1..13]
            month = $("<li>").addClass('month').data("offset", i).html(i)
            @year.append(month)
            month
        
        @calculate()
        
        @target.after @year
    
    calculate: ->
        _year = @date.getFullYear()
        _month= @date.getMonth()
        for month in @months
            date = new Date(@date)
            date.setMonth(month.data("offset"), 1)
            month.data("date", date)
            month.html("<span class=\"month\">#{months[date.getMonth()]}</span><span class=\"year\">#{date.getFullYear()}</span>")
            month.toggleClass("current", date.getMonth() == _month and date.getFullYear() == _year)
            month.toggleClass("active", date.getFullYear() == _year)
            month.toggleClass("passive", date.getFullYear() != _year)
            
        


widget = (element, engine, market, options = {}) ->
    element = $(element); return unless _.size(element) > 0
    
    date = new Date(2012, 11, 1)
    date.setHours(0, 0, 0, 0)

    year_widget = new YearWidget(element, date)

    render_value = ->
        element.html l date
    
    render_value()


$.extend scope,
    date_chooser: widget
