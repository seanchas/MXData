root    = @
scope   = root['mx']['data']


$       = jQuery


security_groups         = mx.iss.security_groups()
security_groups_hash    = undefined
metadata                = mx.iss.metadata()


securities_cache = -> kizzy('data.table')


locales =
    results:
        empty:
            ru: 'По вашему запросу ничего не найдено.'
            en: 'Your search did not match any documents.'



KEY_ESC         = 27


search_delay    = 250
query_threshold = 3



securities_keys = ->
    _.map(metadata.markets, (market) -> "#{market.trade_engine_name}:#{market.market_name}:securities")


check_links_status = (container) ->
    caches = _.chain(securities_keys()).map((key) -> securities_cache().get(key)).compact().flatten().value()
    
    #$('span.link.add', container).show()
    #$('span.link.remove', container).hide()
    
    _.each($('li.record, li.board', container), (item) ->
        item        = $(item)
        item.toggleClass('table', _.include(caches, "#{item.data('board-id')}:#{item.data('security-id')}"))
    )



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



collect_groups = (data) ->
    _.reduce(_.uniq(_.map(data, (record) -> record.group)), (memo, id) ->
        memo.push
            id: id
            title: security_groups_hash[id]?.title
        memo
    , [])



render_results = (container, data) ->
    clear_search_results(container)
    
    current_group   = undefined
    group_container = undefined
    
    
    groups = collect_groups(data)
    
    _.each(groups, (group) ->
        group.records = _.filter(data, (record) -> record.group == group.id)
    )
    
    container.html(ich.query_search_results({ groups: groups }))
    
    check_links_status(container)



render_boards = (container, security_id, data) ->
    container.append(ich.query_search_results_boards({ security_id: security_id, boards: _.filter(data, (record) -> !!record.is_traded ) }).hide())

    check_links_status(container)


toggle_record_boards = (element) ->
    
    boards_list = $('ul.boards', element)
    
    
    if boards_list.length > 0
        # if exists - hide all other boards lists, toggle visibility of this boards list
        
        $('ul.boards', element.closest('.result')).not(boards_list).hide()
        boards_list.toggle()
    else
        # if not exists — load boards for given security, show boards list

        # do nothing if already looking for security boards
        return if element.data('boards_query_performed') ; element.data('boards_query_performed', true)

        performed_query = mx.iss.security_boards(element.data('security-id'), { is_traded: 1 })
    
        performed_query.done ->
            render_boards(element, element.data('security-id'), performed_query.data)
            toggle_record_boards(element)



add_ticker_to_table = (board_id, security_id) ->
    add_or_remove_table_ticker("add", board_id, security_id)


remove_ticker_from_table = (board_id, security_id) ->
    add_or_remove_table_ticker("remove", board_id, security_id)


add_or_remove_table_ticker = (method, board_id, security_id) ->
    board   = _.find(metadata.boards, (board) -> board.boardid == board_id)
    market  = _.find(metadata.markets, (market) -> market.market_id == board.market_id)
    engine  = _.find(metadata.engines, (engine) -> engine.id == board.engine_id)
    
    $(window).trigger "global:table:security:#{method}:#{engine.name}:#{market.market_name}", { ticker: "#{board_id}:#{security_id}" }

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
        
        result_view.on 'click', 'li.record span.boards', (event) -> toggle_record_boards($(@).closest('li'))
        
        result_view.on 'click', 'span.link.add', (event) ->
            item = $(@).closest('li') ; add_ticker_to_table(item.data('board-id'), item.data('security-id'))
        
        result_view.on 'click', 'span.link.remove', (event) ->
            item = $(@).closest('li') ; remove_ticker_from_table(item.data('board-id'), item.data('security-id'))
        
        $(window).on 'global:table:security:added global:table:security:removed', -> _.defer check_links_status, result_view


$.extend scope,
    quote_search: widget
