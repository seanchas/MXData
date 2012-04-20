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


###


make_tag = (value) ->
    $("<td>").addClass("tag").append($("<div>").html(value).append($("<a>").attr("href", "").html("[x]")))


build_securities_list = (element) ->
    container = $("<div>").addClass("quote_search_securities_container")
    
    table = $("<table>")
        .html("<thead></thead><tbody></tbody>")
    
    container.html(table)
    container.hide()
    
    element.after(container)
    
    container


buildBoardsList = (element) ->
    container = $("<div>").addClass("quote_search_boards_container")
    
    table = $("<table>")
        .html("<thead></thead><tbody></tbody>")
    
    container.html(table)
    container.hide()
    
    element.after(container)
    
    container



widget = (element, options = {}) ->
    element = $(element); return unless _.size(element) > 0
    
    last_query      = undefined
    query_timeout   = undefined


    query_input = $("td.query input",   element)
    
    securities_list_container = build_securities_list(element)
    securities_list = $("tbody", securities_list_container)
    
    boards_list_container = buildBoardsList(element)
    boards_list = $("tbody", boards_list_container)
    
    security_groups = {}

    onSecuritySearchComplete = (json) ->
        securities_list.empty()
        
        groups  = []
        records = {}
        
        make_row = ->
            $("<tr>").appendTo(securities_list)
        
        make_divider_row = ->
            $("<tr>").addClass("divider").html("<td colspan=\"2\"><hr /></td>").appendTo(securities_list)
        
        for record in json
            groups.push(record.group) unless _.include(groups, record.group)
            (records[record.group] ||= []).push(record)
            
        for group, i in groups
            make_divider_row() unless i == 0

            row = make_row()
            row.append($("<th>").html(security_groups[group].title).attr("rowspan", _.size(records[group])))

            for record in records[group]
                row ||= make_row()
                row.append($("<td>").attr('data-secid', record.secid).html("<span>#{record.shortname}</span> (<span>#{record.secid}</span>)<span class=\"name\">#{record.name}</span>"))
                row = null
                
        
        securities_list_container.show()
    
    onSecurityBoardsLoadComplete = (data) ->
        boards_list.empty()
        for record in data when record.is_traded == 1
            boards_list.append $("<tr>")
                .attr("data-param", "#{record.engine}:#{record.market}:#{record.boardid}:#{record.secid}")
                .append($("<th>").html(record.boardid))
                .append($("<td>").html(record.title))
        
        boards_list_container.show()
        
    search = (query) ->
        return if last_query == query
        last_query = query
        return if query.length < search_query_threshold
        mx.iss.quote_search(query, { group_by: 'group', is_traded: 1 }).then onSecuritySearchComplete
    
    chooseSecurity = (event) ->
        secid = $(event.currentTarget).data('secid')
        $("table tbody tr", element).prepend(make_tag(secid))
        query_input.val("")
        query_input.focus()
        securities_list_container.hide()
        fsm.clarify()
        mx.iss.security_boards(secid).then onSecurityBoardsLoadComplete
    
    chooseTicker = (event) ->
        [engine, market, board, param] = $(event.currentTarget).data('param').split(":")
        closeTag()
        $(window).trigger("security:selected", { engine: engine, market: market, board: board, param: param })
        
        
    
    closeTag = (event) ->
        event.preventDefault() if event?
        $("td.tag").remove()
        query_input.val("")
        query_input.focus()
        securities_list_container.hide()
        boards_list_container.hide()
        

    mx.iss.security_groups().then (json) ->
        for group in json
            security_groups[group.name] = group


    fsm_timeout = undefined

    fsm = StateMachine.create
    
        events: [
            {
                name:   'startup'
                from:   'none'
                to:     'security'
            }
            {
                name:   'clarify'
                from:   'security'
                to:     'board'
            }
            {
                name:   'shutdown'
                from:   '*'
                to:     'none'
            }
        ]
        
        callbacks:
            
            onstartup: ->
                element.addClass "active"
                #console.log "startup"
            
            onclarify: ->
                #console.log "clarify"
            
            onshutdown: ->
                element.removeClass "active"
                #console.log "shutdown"


    query_input.on "focus", -> fsm.startup()

    query_input.on "blur",  -> fsm.shutdown()

    query_input.on "keyup", (event) ->
        query = query_input.val()
        return unless query?
        clearTimeout query_timeout
        query_timeout = _.delay search, search_timeout, query
    
    securities_list_container.on "click", "td[data-secid]", chooseSecurity
    boards_list_container.on "click", "tr[data-param]", chooseTicker
    element.on "click", "td.tag a", closeTag
    
###


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

render_securities_list = (container, groups, records) ->
    for group in groups
        
        row     = $('<tr>')
        cell    = $('<td>')
        list    = $('<ul>')

        for record in records[group]
            list.append $('<li>')
                .data('param', "#{record.primary_boardid}:#{record.secid}")
                .html(record.shortname)
                .append($('<span>').addClass('title').html(record.name))

        cell.append         list
        row.append          $('<th>').html(group)
        row.append          cell
        container.append    row
    


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
    
    securities_list_wrapper = build_securities_list wrapper
    securities_list         = $ 'tbody', securities_list_wrapper
    
    items                       = undefined
    selected_item               = undefined
    
    last_cursor_position        = undefined
    mouse_locked                = false

    # fsm
    
    machine = StateMachine.create
        initial: 'inactive'
        events: [
            { name: 'next',         from: 'inactive',   to: 'initial'   }
            { name: 'next',         from: 'initial',    to: 'quotes'    }
            { name: 'next',         from: 'quotes',     to: 'boards'    }

            { name: 'prev',         from: 'boards',     to: 'quotes'    }
            { name: 'prev',         from: 'quotes',     to: 'initial'   }
            { name: 'prev',         from: 'initial',    to: 'inactive'  }
            { name: 'prev',         from: 'inactive',   to: 'inactive'  }
            
            { name: 'on',           from: 'inactive',   to: 'initial'   }
            { name: 'off',          from: '*',          to: 'inactive'  }
        ]
        callbacks:
            onenterinitial:     ->

            onenterquotes:      ->
                

            onenterboards:      ->

            onenterinactive:    ->
                wrapper.removeClass 'active'

            onleaveinitial:     ->

            onleavequotes:      ->
                items           = undefined
                selected_item   = undefined
                hide_quotes()

            onleaveboards:      ->

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
    
    # navigation
    
    render_selected_item = ->
        return unless items and selected_item

        items.removeClass 'selected'
        selected_item.addClass 'selected'
        
        scroll_top      = securities_list_wrapper.scrollTop()
        item_top        = selected_item.offset().top
        item_height     = selected_item.outerHeight()
        wrapper_top     = securities_list_wrapper.offset().top
        wrapper_height  = securities_list_wrapper.innerHeight()

        top_overlap     = item_top - wrapper_top
        bottom_overlap  = (wrapper_top + wrapper_height) - (item_top + item_height)
        
        if top_overlap < 0
            securities_list_wrapper.scrollTop(scroll_top + top_overlap)
            return
        
        if bottom_overlap < 0
            securities_list_wrapper.scrollTop(scroll_top - bottom_overlap)
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
        scroll_top      = securities_list_wrapper.scrollTop()
        wrapper_height  = securities_list_wrapper.innerHeight()
        securities_list_wrapper.scrollTop(scroll_top - wrapper_height)
        
        no_move = Math.abs(scroll_top - securities_list_wrapper.scrollTop()) < wrapper_height
        
        visible = visible_items_in(securities_list_wrapper)
        
        selected_item = $ if no_move then _.first visible else _.last visible
        render_selected_item()

    page_down = ->
        scroll_top      = securities_list_wrapper.scrollTop()
        wrapper_height  = securities_list_wrapper.innerHeight()
        securities_list_wrapper.scrollTop(scroll_top + securities_list_wrapper.innerHeight())
        
        no_move = Math.abs(scroll_top - securities_list_wrapper.scrollTop()) < wrapper_height
        
        visible = visible_items_in(securities_list_wrapper)

        selected_item = $ if no_move then _.last visible else _.first visible
        render_selected_item()
        

    # event listeners
    
    query_input.on 'focus', (event) ->
        clearTimeout timeout_for_deactivation
        machine.on() if machine.current == 'inactive'
    
    query_input.on 'blur', (event) ->
        clearTimeout timeout_for_deactivation ; timeout_for_deactivation = _.delay ( -> machine.off() ), deactivation_timeout
    
    query_input.on 'keydown', (event) ->
        mouse_locked = true
        
        if event.keyCode == KEY_PAGE_DOWN
            page_down()
            return false;

        if event.keyCode == KEY_PAGE_UP
            page_up()
            return false;

        if event.keyCode == KEY_DOWN
            select_next_item()
            return false

        if event.keyCode == KEY_UP
            select_prev_item()
            return false

    query_input.on 'keyup', (event) ->
        if event.keyCode == KEY_ESC
            query_input.blur() if machine.current == 'initial' ; return machine.prev()
        clearTimeout timeout_for_process_query ; timeout_for_process_query = _.delay ( -> quotes_search_with_query_check query_input.val() ), search_timeout
    
    securities_list.on 'click', 'li', (event) ->
        hide_quotes()
    
    securities_list.on 'mouseenter', 'li', (event) ->
        if mouse_locked then mouse_locked = false ; return
        selected_item = $(event.currentTarget)
        render_selected_item()
    
        
    
$.extend scope,
    quote_search: widget
