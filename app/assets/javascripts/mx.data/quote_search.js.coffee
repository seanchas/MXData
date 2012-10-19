root    = @
scope   = root['mx']['data']


$       = jQuery


security_groups         = mx.iss.security_groups()
security_groups_hash    = undefined
metadata                = mx.iss.metadata()



locales =
    results:
        empty:
            ru: 'Ничего не найдено'
            en: 'Nothing has been found'



KEY_ESC         = 27


search_delay    = 250
query_threshold = 3



# NB!!! Delete and replace with common utility function

render_date = (string) ->
    date = new Date(Date.parse(string))
    f = (n) -> if n < 10 then "0#{n}" else n
    "#{f date.getDate()}.#{f(date.getMonth() + 1)}.#{date.getFullYear()}"


populate_security_groups_hash = ->
    security_groups_hash = _.reduce security_groups.data, 
        (memo, item) ->
            memo[item.name] = item ; memo
    , {}



make_filter_view = (container) ->
    view = $('<div>')
        .addClass('filter')

    view
        .appendTo(container)



make_result_view = (container) ->
    view = $('<div>')
        .addClass('result')
        .appendTo(container)
    
    calculate_result_view_max_height(view)
    
    view


calculate_result_view_max_height = (view) ->
    view.css('max-height', $(window).height() - view.offset().top - 20)


clear_search_results = (container) ->
    container.empty()


collect_emitters = (data) ->
    emitters = []
    emitters_ids = []
    
    for record in data
        if record.emitent_id
            unless _.include(emitters_ids, record.emitent_id)
                emitters_ids.push(record.emitent_id)
                emitters.push({ id: record.emitent_id, name: record.emitent_title })
    
    emitters



render_results = (container, data) ->
    clear_search_results(container)
    
    current_group   = undefined
    group_container = undefined
    
    
    render_emitters(container, collect_emitters(data))
    
    
    groups_container = $('<ul>')
        .addClass('groups')
        .appendTo(container)

    for record in data
        
        unless current_group == record.group
            group = make_group(record.group).appendTo(groups_container)
            group_container = $('ul', group)
            current_group = record.group

        group_container.append(make_record(record))

    container.append(make_empty) if _.isEmpty(data)



render_emitters = (container, data) ->
    emitters_container = $('<ul>')
        .addClass('emitters')
        .appendTo(container)
    
    $('<li>')
        .addClass('title')
        .html('Эмитенты')
        .appendTo(emitters_container)
    
    for record in data
        render_emitter(emitters_container, record)


render_emitter = (container, data) ->
    emitter = $('<li>')
        .data('id', data.id)
        .addClass('emitter')
        .appendTo(container)
    
    $('<span>')
        .addClass('name')
        .html(data.name)
        .appendTo(emitter)
    
    emitter



toggle_emitter_securities = (element) ->
    list = $('ul.records', element)
    
    if list.length > 0
        $('ul.records', element.closest('ul.emitters')).not(list).hide()
        list.toggle()
    else
        return if element.data('securities-query-performed') == true ; element.data('securities-query-performed', true)

        mx.iss.emitter_securities(element.data('id')).done (data) ->
            render_emitter_securities(element, data).hide()
            toggle_emitter_securities(element)
            

render_emitter_securities = (container, data) ->
    securities_container = $('<ul>')
        .addClass('records')
        .appendTo(container)
    
    for record in data
        render_emitter_security(securities_container, record)
    
    securities_container


render_emitter_security = (container, data) ->
    security = $('<li>')
        .data('id', data.SECID)
        .addClass('record')
        .appendTo(container)
    
    $('<span>')
        .addClass('shortname')
        .html(data.SHORTNAME)
        .appendTo(security)
    
    $('<strong>')
        .addClass('type')
        .html(data.SECURITY_TYPE)
        .appendTo(security)

    $('<em>')
        .addClass('name')
        .html(data.NAME)
        .appendTo(security)
    
    security


make_group = (id) ->
    $('<li>')
        .addClass('group')
        .append($('<span>').html(security_groups_hash[id]?.title))
        .append($('<ul>').addClass('records'))


make_record = (record) ->
    $('<li>')
        .data('id', record.secid ? '')
        .addClass('record')
        .append($('<span>').html(record.shortname))
        .append($('<em>').html(record.name))
        .append($('<em>').html(record.emitent_title))
        


make_empty = ->
    $('<li>')
        .addClass('empty')
        .html(locales.results.empty['ru'])



render_boards_list = (data) ->
    boards_list = $('<ul>')
        .addClass('boards')
    
    for record in data when !!record.is_traded
        make_board(record).appendTo(boards_list)
    
    boards_list


make_board = (record) ->
    board = $('<li>')
        .addClass('board')
        .append($('<strong>').html(record.boardid))
        .append($('<span>').html(record.title))
    
    if record.listed_from and record.listed_till
        $('<em>')
            .append($('<span>').html('Листинг'))
            .append($('<span>').html(render_date record.listed_from))
            .append($('<span>').html(render_date record.listed_till))
            .appendTo(board)
    
    ###
    if record.history_from and record.history_till
        $('<em>')
            .append($('<span>').html('История'))
            .append($('<span>').html(render_date record.listed_from))
            .append($('<span>').html(render_date record.listed_till))
            .appendTo(board)
    ###
    
    board



toggle_record_boards = (element) ->
    boards_list = $('ul.boards', element)
    
    # if exists - hide all other boards lists, toggle visibility of this boards list
    
    if boards_list.length > 0
        $('ul.boards', element.closest('.result')).not(boards_list).hide()
        boards_list.toggle()
        return
    
    # if not exists — load boards for given security, show boards list

    # do nothing if already looking for security boards
    return if element.data('boards_query_performed') ; element.data('boards_query_performed', true)

    performed_query = mx.iss.security_boards(element.data('id'), { is_traded: 1 })
    
    performed_query.done ->
        render_boards_list(performed_query.data).appendTo(element).hide()
        toggle_record_boards(element)


widget = (container, options = {}) ->
    container = $(container) ; return if container.length == 0
    
    query_input_view    = undefined
    filter_view         = undefined
    result_view         = undefined
    
    
    search_timeout      = undefined
    performed_query     = undefined
    performed_search    = undefined
    

    filter_markets  = scope.quote_search_filter_markets()


    ready = $.when(metadata, security_groups, filter_markets)
    
    
    search = (query) ->
        performed_query  = query
        performed_search = mx.iss.quote_search(performed_query, { group_by: 'group', is_traded: 1 })

        performed_search.done ->
            render_results(result_view, performed_search.data) if query == performed_search.query
        
                
    
    observe_window_keyboard_events = (event) ->
        switch event.keyCode
            when KEY_ESC
                if query_input_view.is(':focus')
                    query_input_view.blur()
                else
                    query_input_view.select()
    

    observe_query_input = (event) ->
        
        query = $.trim(query_input_view.val())

        clearTimeout search_timeout

        if query.length < query_threshold
            clear_search_results(result_view)
            performed_query = undefined
            return
        
        if performed_query == query
            return
        else
            search_timeout = _.delay(search, search_delay, query)
        
        
    
    ready.then ->
        
        populate_security_groups_hash()
        
        query_input_view    = $('input[type=text]', container)
        filter_view         = make_filter_view(container)
        result_view         = make_result_view(container)

        filter_view.append(filter_markets.view())
        

        $(window).on 'keyup', observe_window_keyboard_events
        
        $(window).on 'resize', -> calculate_result_view_max_height(result_view)

        query_input_view.on 'keyup', observe_query_input
        
        result_view.on 'click', 'li.record > span', (event) -> toggle_record_boards($(@).closest('li'))

        result_view.on 'click', 'li.emitter > span', (event) -> toggle_emitter_securities($(@).closest('li'))



$.extend scope,
    quote_search: widget
