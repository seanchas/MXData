root    = @
scope   = root['mx']['data']


$       = jQuery


search_query_threshold  = 3
search_timeout          = 300
deactivation_timeout    = 50

KEY_ESC         = 27
KEY_ENTER       = 13
KEY_UP          = 38
KEY_DOWN        = 40
KEY_PAGE_UP     = 33
KEY_PAGE_DOWN   = 34


build_securities_list = (wrapper) ->
    container = $('<div>').addClass('quote_search_securities_container')
    
    table = $('<table>')
        .html('<thead></thead><tbody></tbody>')
    
    container.html(table)
    container.hide()
    
    offset = wrapper.offset()
    
    offset.top = offset.top + wrapper.outerHeight() + 2
    
    wrapper.after(container)

    container.offset(offset)
    
    container


build_boards_list = (wrapper) ->
    container = $('<div>').addClass('quote_search_boards_container')
    
    table = $('<table>')
        .html('<thead></thead><tbody></tbody>')
    
    container.html table
    container.hide()
    
    offset      = wrapper.offset()
    offset.top  = offset.top + wrapper.outerHeight() + 2
    
    wrapper.after container
    container.offset offset

    container


render_securities_list = (container, groups, records) ->
    for group in groups
        
        row     = $('<tr>')
        cell    = $('<td>')
        list    = $('<ul>')

        for record in records[group]
            list.append $('<li>')
                .attr('data-param', "#{record.primary_boardid}:#{record.secid}")
                .html(record.shortname)
                .append($('<span>').addClass('title').html(record.name))

        cell.append         list
        row.append          $('<th>').html(group)
        row.append          cell
        container.append    row
    

render_boards_list = (container, boards) ->
    for board in boards
        
        row = $('<tr>')
            .data('param', board)
        
        row.append $('<th>').html(board.boardid)
        row.append $('<td>').addClass('title').html(board.title)
        
        container.append row
        


widget = (wrapper, options = {}) ->
    wrapper = $(wrapper); return if _.size(wrapper) == 0
    
    container       = $('tr', wrapper)
    query_input     = $('td.query input', wrapper)
    clear_button    = $('td.clear', wrapper)
    busy_spinner    = $('td.busy', wrapper)
    
    timeout_for_deactivation    = undefined
    timeout_for_process_query   = undefined
    pending_query               = undefined
    pending_promise             = undefined
    
    securities_list_wrapper     = build_securities_list wrapper
    securities_list             = $ 'tbody', securities_list_wrapper
    security                    = undefined
    
    boards_list_wrapper         = build_boards_list wrapper
    boards_list                 = $ 'tbody', boards_list_wrapper
    
    items                       = undefined
    selected_item               = undefined
    items_list                  = undefined
    
    last_cursor_position        = undefined
    mouse_locked                = false

    # fsm
    
    machine = StateMachine.create
        initial: 'inactive'
        events: [
            { name: 'next',         from: 'inactive',   to: 'initial'   }
            { name: 'next',         from: 'initial',    to: 'quotes'    }
            { name: 'next',         from: 'quotes',     to: 'boards'    }

            { name: 'prev',         from: 'boards',     to: 'initial'   }
            { name: 'prev',         from: 'quotes',     to: 'initial'   }
            { name: 'prev',         from: 'initial',    to: 'inactive'  }
            { name: 'prev',         from: 'inactive',   to: 'inactive'  }
            
            { name: 'on',           from: 'inactive',   to: 'initial'   }
            { name: 'off',          from: '*',          to: 'inactive'  }
        ]
        callbacks:
            onenterinitial:     ->

            onenterquotes:      ->
                items_list      = securities_list_wrapper

            onenterboards:      ->
                query_input.val('')
                items_list      = boards_list_wrapper
                add_tag _.last(security.split(':'))

            onenterinactive:    ->
                pending_query   = undefined
                wrapper.removeClass 'active'
                query_input.blur()

            onleaveinitial:     ->

            onleavequotes:      ->
                hide_quotes()
                items           = undefined
                selected_item   = undefined
                items_list      = undefined

            onleaveboards:      ->
                items           = undefined
                selected_item   = undefined
                security        = undefined
                remove_tag()
                hide_boards()

            onleaveinactive:    ->
                wrapper.addClass 'active'
    
    # utilities
    
    add_tag = (name) ->
        remove_tag()
        container.prepend $('<td>').addClass('tag').html($('<div>').html(name))

    remove_tag = ->
        $('td.tag', wrapper).remove()
    
    hide_quotes = ->
        securities_list_wrapper.hide()
        securities_list.empty()
    
    hide_boards = ->
        boards_list_wrapper.hide()
        boards_list.empty()
    
    # search
    
    quotes_search_with_query_check = (query) ->
        machine.prev() if query.length < search_query_threshold and machine.current == 'quotes'

        return if pending_query == query
        pending_query = query

        return if query.length < search_query_threshold
        
        search_quotes()
    
    search_quotes = ->
        busy_spinner.show()
        mx.iss.quote_search(pending_query, { group_by: 'group', is_traded: 1 }).done on_quotes_search_complete
    
    search_boards = ->
        busy_spinner.show()
        mx.iss.security_boards(_.last(security.split(':')), { is_traded: 1 }).done on_boards_search_complete

    on_quotes_search_complete = (data) ->
        machine.next() unless machine.current == 'quotes'
        hide_quotes()
        
        groups = [] ; records = {}
        
        for record in data
            groups.push record.group unless _.include groups, record.group
            (records[record.group] ?= []).push record
        
        render_securities_list securities_list, groups, records
        securities_list_wrapper.show()
        
        items           = $('li', securities_list_wrapper)
        selected_item   = items.first()
        render_selected_item()
        
        busy_spinner.hide()
    
    on_boards_search_complete = (data) ->
        machine.next() unless machine.current == 'boards'
        hide_boards()
        
        render_boards_list boards_list, data
        boards_list_wrapper.show()

        items           = $('tr', boards_list_wrapper)
        selected_item   = items.first()
        render_selected_item()

        busy_spinner.hide()
    
    # navigation
    
    render_selected_item = ->
        return unless items and selected_item and items_list

        items.removeClass 'selected'
        selected_item.addClass 'selected'
        
        scroll_top      = items_list.scrollTop()
        item_top        = selected_item.offset().top
        item_height     = selected_item.outerHeight()
        wrapper_top     = items_list.offset().top
        wrapper_height  = items_list.innerHeight()

        top_overlap     = item_top - wrapper_top
        bottom_overlap  = (wrapper_top + wrapper_height) - (item_top + item_height)
        
        if top_overlap < 0
            items_list.scrollTop(scroll_top + top_overlap)
            return
        
        if bottom_overlap < 0
            items_list.scrollTop(scroll_top - bottom_overlap)
            return
            
    
    select_prev_item = ->
        return unless items and selected_item
        return if selected_item.data('param') == items.first().data('param')

        selected_item = $(items[items.index(selected_item) - 1])
        render_selected_item()
        
    
    select_next_item = ->
        return unless items and selected_item
        return if selected_item.data('param') == items.last().data('param')
        
        selected_item = $(items[items.index(selected_item) + 1])
        render_selected_item()
    
    visible_items_in = (container) ->
        container_top     = container.offset().top
        container_height  = container.innerHeight()
        
        _.filter items, (item) ->
            item = $(item)
            
            item_top        = item.offset().top
            item_height     = item.outerHeight()

            top_visible     = item_top + item_height - container_top > 0
            bottom_visible  = item_top - container_top < container_height
            
            return top_visible and bottom_visible
        
    
    page_up = ->
        scroll_top      = items_list.scrollTop()
        wrapper_height  = items_list.innerHeight()
        items_list.scrollTop(scroll_top - wrapper_height)
        
        no_move = Math.abs(scroll_top - items_list.scrollTop()) < wrapper_height
        
        visible = visible_items_in(items_list)
        
        selected_item = $ if no_move then _.first visible else _.last visible
        render_selected_item()

    page_down = ->
        scroll_top      = items_list.scrollTop()
        wrapper_height  = items_list.innerHeight()
        items_list.scrollTop(scroll_top + items_list.innerHeight())
        
        no_move = Math.abs(scroll_top - items_list.scrollTop()) < wrapper_height
        
        visible = visible_items_in(items_list)

        selected_item = $ if no_move then _.last visible else _.first visible
        render_selected_item()
    
    accept_selected_item = (event) ->
        switch machine.current
            when 'quotes' then accept_quote event, selected_item.data('param')
            when 'boards' then accept_board event, selected_item.data('param')
    
    accept_quote = (event, quote) ->
        security = quote
        hide_quotes()
        machine.next()
        search_boards()
    
    accept_board = (event, board) ->
        machine.off() unless event.shiftKey == true
        $(window).trigger("security:selected", { engine: board.engine, market: board.market, board: board.boardid, param: board.secid })

    # event listeners
    
    query_input.on 'focus', (event) ->
        clearTimeout timeout_for_deactivation
        machine.on() if machine.current == 'inactive'
    
    query_input.on 'blur', (event) ->
        clearTimeout timeout_for_deactivation ; timeout_for_deactivation = _.delay ( -> machine.off() ), deactivation_timeout
    
    query_input.on 'keydown', (event) ->
        mouse_locked = true
        
        switch event.keyCode
            when KEY_PAGE_UP    then page_up()                      ; return false
            when KEY_PAGE_DOWN  then page_down()                    ; return false
            when KEY_UP         then select_prev_item()             ; return false
            when KEY_DOWN       then select_next_item()             ; return false
            when KEY_ENTER      then accept_selected_item(event)    ; return false


    query_input.on 'keyup', (event) ->
        if event.keyCode == KEY_ESC
            query_input.blur() if machine.current == 'initial' ; return machine.prev()
        if machine.current == 'initial' or machine.current == 'quotes'
            clearTimeout timeout_for_process_query ; timeout_for_process_query = _.delay ( -> quotes_search_with_query_check query_input.val() ), search_timeout
    
    # quotes events
    
    securities_list.on 'click', 'li', (event) ->
        accept_quote event, $(event.currentTarget).data('param')
    
    securities_list.on 'mouseenter', 'li', (event) ->
        if mouse_locked then mouse_locked = false ; return
        selected_item = $(event.currentTarget)
        render_selected_item()
    
    boards_list.on 'click', 'tr', (event) ->
        accept_board event, $(event.currentTarget).data('param')

    boards_list.on 'mouseenter', 'tr', (event) ->
        if mouse_locked then mouse_locked = false ; return
        selected_item = $(event.currentTarget)
        render_selected_item()
    
    # window events

    $(document).on 'focusout', (event) ->
        query_input.val('')
        
    
$.extend scope,
    quote_search: widget
