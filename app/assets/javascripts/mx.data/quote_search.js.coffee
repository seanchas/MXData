root    = @
scope   = root['mx']['data']


$       = jQuery


security_groups         = mx.iss.security_groups()
security_groups_hash    = undefined
metadata                = mx.iss.metadata()
metadata_engines_hash   = undefined
metadata_markets_hash   = undefined
metadata_boards_hash    = undefined


securities_cache = -> kizzy('data.table')


KEY_ESC         = 27


search_delay    = 250
query_threshold = 3



securities_keys = ->
    _.map(metadata.markets, (market) -> "#{market.trade_engine_name}:#{market.market_name}:securities")


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


populate_metadata_boards_hash = ->
    metadata_boards_hash = _.reduce metadata.boards,
        (memo, item) ->
            memo[item.boardid] = item ; memo
    , {}



make_filter_view = (container) ->
    view = $('<div>')
        .addClass('filter')

    view
        .appendTo(container)


make_result_view = (container) ->
    view = $('<ul>')
        .addClass('results')
        .appendTo(container)
    
    calculate_result_view_max_height(view)
    
    view


calculate_result_view_max_height = (view) ->
    view.css('max-height', $(window).height() - view.offset().top - 20)


clear_search_results = (container) ->
    container.empty()


collect_groups = (data) ->
    _.reduce(_.uniq(_.map(data, (record) -> record.group)), (memo, id) ->
        memo.push
            id: id
            title: security_groups_hash[id]?.title
        memo
    , [])


render_results = (container, data) ->
    clear_search_results(container)
    
    groups = collect_groups(data)
    
    _.each(groups, (group) -> group.records = _.filter(data, (record) -> record.group == group.id))
    
    _.each(data, (record) ->
        record.boards = []
        record.boards.push _.find(metadata.boards, (board) -> board.boardid == record.primary_boardid)
    )
    
    container.html(ich.query_search_results({ groups: groups }))

    set_primary_boards(container)
    set_boards_statuses(container)


render_boards = (container, data) ->
    boards = _.chain(data).reject((board) -> !board.is_traded).map((board) -> metadata_boards_hash[board.boardid]).value()
    
    container.append(ich.query_search_results_boards({ boards: boards }))
    
    set_boards_statuses(container)


set_primary_boards = (container) ->
    _.each($('li.security', container), (security) ->
        security = $(security)
        _.each($('li.board', security), (board) ->
            board = $(board) ; board.addClass('primary') if board.data('id') == security.data('primary-board-id')
        )
    )


set_boards_statuses = (container) ->
    caches = _.chain(securities_keys()).map((key) -> securities_cache().get(key)).compact().flatten().value()
    
    _.each($('li.board', container), (board) ->
        board       = $(board)
        security    = board.closest('li.security')
        board.toggleClass('active', _.include(caches, [board.data('id'), security.data('id')].join(':')))
    )


toggle_security_boards = (element) ->
    if element.data('boards-loaded') == true
        #element.siblings('li.security').addClass('primary')
        element.toggleClass('primary')
    else
        return if element.data('boards-loaded')? ; element.data('boards-loaded', false)

        mx.iss.security_boards(element.data('id')).done (data) ->
            render_boards($('ul.boards', element), _.reject(data, (board) -> board.boardid == element.data('primary-board-id')))
            element.data('boards-loaded', true) ; toggle_security_boards(element)


toggle_ticker_in_table = (element) ->
    board_id    = element.data('id')
    security_id = element.closest('li.security').data('id')

    if element.hasClass('active')
        remove_ticker_from_table(board_id, security_id)
    else
        add_ticker_to_table(board_id, security_id)


add_ticker_to_table = (board_id, security_id) ->
    add_or_remove_table_ticker("add", board_id, security_id)


remove_ticker_from_table = (board_id, security_id) ->
    add_or_remove_table_ticker("remove", board_id, security_id)


add_or_remove_table_ticker = (method, board_id, security_id) ->
    board   = _.find(metadata.boards,   (board)     -> board.boardid    == board_id)
    market  = _.find(metadata.markets,  (market)    -> market.market_id == board.market_id)
    engine  = _.find(metadata.engines,  (engine)    -> engine.id        == board.engine_id)
    
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
        populate_metadata_boards_hash()
        
        query_input_view    = $('input[type=text]', container)
        filter_view         = make_filter_view(container)
        result_view         = make_result_view(container)

        filter_view.append(filter_markets.view())
        

        $(window).on 'keyup', observe_window_keyboard_events
        
        $(window).on 'resize', -> calculate_result_view_max_height(result_view)

        query_input_view.on 'keyup', observe_query_input
        

        result_view.on 'click', 'li.security > p.links a', (event) ->
            event.preventDefault()
            toggle_security_boards($(@).closest('li.security'))
        

        result_view.on 'click', 'li.board a', (event) ->
            event.preventDefault()
            toggle_ticker_in_table($(@).closest('li.board'))
        

        $(window).on 'global:table:security:added global:table:security:removed', -> _.defer set_boards_statuses, result_view


$.extend scope,
    quote_search: widget
