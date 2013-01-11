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

default_weekday_offset = 1


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
    constructor: (@target, @dates, date) ->
        @prepare()
        @start_event_listeners()
        @set_date(date)
    
    show: ->
        @render()
        @table.show()
    
    hide: ->
        @table.hide()
    
    start_event_listeners: ->
        @table.on "mouseleave", @on_mouse_leave
    
    prepare: ->
        @table = $("<table>").addClass("month").html("<thead></thead><tbody></tbody>")
        
        table_head = $("thead", @table)
        table_body = $("tbody", @table)
        
        date_row = $("<tr>")
        @date_cell = $("<th>").attr("colspan", 7)
        table_head.append date_row.append @date_cell
        
        weekdays_row = $("<tr>")
        table_head.append weekdays_row
        for i in [0..6]
            weekdays_row .append $("<td>").html(weekdays[(i + default_weekday_offset) % 7])
        
        @cells = []
        
        for i in [0..5]
            row = $("<tr>")            
            for j in [0..6]
                cell = $("<td>")
                @cells.push cell
                row.append cell
            
            table_body.append(row)
        
        @table.hide()
        
        @target.after @table
    
    set_date: (date) ->
        @date = date
        @year   = @date.getFullYear()
        @month  = @date.getMonth()
        @day    = @date.getDate()
        
        @rendered = false
        
        @recalculate()
    
    recalculate: ->
        
        start           = new Date(@dates[@month + 1].date - @dates[@month + 1].date_offset * day_in_millis)
        @start_date     = start.getDate()
        @start_day      = + start
        @first_day      = + @dates[@month + 1].date
        @last_day       = + @dates[@month + 2].prev_date
    
    position_at: (element) ->
        @render()
        @table.show()

        [height, width] = [@table.outerHeight(), @table.outerWidth()]
        
        [element_height, element_width] = [element.innerHeight(), element.innerWidth()]
        element_position = element.offset()
        
        @table.offset
            top:    element_position.top + element_height / 2 - height / 2
            left:   element_position.left + element_width / 2 - width / 2
        
        @table.hide()
        
    render: ->
        return if @rendered
        
        @date_cell.html("#{months[@month]} #{@year}")
        
        is_current_month    = false
        cursor              = @start_date

        for i in [0...42]
            current_day = i * day_in_millis + @start_day

            if current_day == @first_day
                is_current_month = true
                cursor = 1

            if current_day - day_in_millis == @last_day
                is_current_month = false
                cursor = 1
                
            @cells[i]
                .toggleClass('active',  is_current_month)
                .toggleClass('passive', !is_current_month)
                .html(cursor)

            cursor++
        
        @rendered = true
        
    on_mouse_leave: (event) =>
        @hide()
            
    

class YearWidget

    constructor: (@target, date) ->
        @prepare()
        @start_event_listeners()
        @set_date(date)
        @show()
        @month_widget = new MonthWidget(@year_view, @dates, date)
    
    show: ->
        @render()
        @year_view.show()
    
    hide: ->
        @year_view.hide()
    
    start_event_listeners: ->
        @year_view.on "mouseenter click", "li.month.active", @on_mouse_enter
        @year_view.on "click", "li.month.passive", @on_change_year_click
    
    prepare: ->
        @year_view = $("<ul>").addClass("year")
        @month_views = for i in [0..14]
            month_view = $("<li>")
                .addClass("month")
                .toggleClass("active",  i > 0 and i < 13)
                .toggleClass("passive", i < 1 or  i > 12)
                .toggleClass("prev", i < 1)
                .toggleClass("next", i > 12)
                .html("<span class=\"month\">#{ months[(11 + i) % 12] }</span><span class=\"year\"></span>")

            month_view.data
                index:  i
                month:  $('.month', month_view)
                year:   $('.year',  month_view)

            @year_view.append month_view
            month_view
        
        @target.after @year_view
        
    set_date: (date) ->
        @date = date
        @year   = @date.getFullYear()
        @month  = @date.getMonth()
        @day    = @date.getDate()
        
        @rendered = false
        
        @recalculate()
    
    recalculate: ->
        year    = @year - 1
        month   = 11
        dates = for offset in [0..15]
            if month > 11 then [month, year] = [0, year + 1]
            
            date        = new Date(year, month, 1)

            date_offset = date.getDay() - default_weekday_offset
            if date_offset < 0 then date_offset += 7 

            prev_date   = new Date(date.getTime() - day_in_millis)
            
            month++
            
            {
                date:           date
                date_offset:    date_offset
                prev_date:      prev_date
            }
        
        for date, index in dates
            date.last_date = dates[index + 1]?.prev_date
        
        @dates = dates[0..14]
    
    render: ->
        return if @rendered
        
        for i in [0..14]
            month_view = @month_views[i]
            year_view = month_view.data('year')
            year_view.html( if i == 0 then @year - 1 else if i > 12 then @year + 1 else @year)
            if i > 0 and i < 13 then month_view.toggleClass('current', (i - 1) == @month)
        
        @rendered = true
    
    on_mouse_enter: (event) =>
        month_view = $(event.currentTarget)
        @month_widget.set_date(@dates[month_view.data('index')].date)
        @month_widget.position_at(month_view)
        @month_widget.show()
    
    on_change_year_click: (event) =>
        month_view = $(event.currentTarget) 
        @set_date(new Date((if month_view.hasClass("prev") then @year - 1 else @year + 1), 0, 1))
        @show()


widget = (element, engine, market, options = {}) ->
    element = $(element); return unless _.size(element) > 0
    
    date = new Date(2012, 8, 19)
    date.setHours(0, 0, 0, 0)

    year_widget = new YearWidget(element, date)

    render_value = ->
        element.html l date
    
    render_value()


$.extend scope,
    date_chooser: widget
