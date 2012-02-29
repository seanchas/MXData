root    = @
scope   = root['mx']['data']


$       = jQuery


search_query_threshold = 3
search_timeout = 300



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
        
        console.log boards_list_container
        
    onFocus = (event) ->
        element.addClass("active")
    
    onBlur = (event) ->
        element.removeClass("active")

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
        mx.iss.security_boards(secid).then onSecurityBoardsLoadComplete
    
    chooseTicker = (event) ->
        [engine, market, board, param] = $(event.currentTarget).data('param').split(":")
        
        
    
    closeTag = (event) ->
        event.preventDefault()
        $("td.tag").remove()
        query_input.val("")
        query_input.focus()
        securities_list_container.hide()
        boards_list_container.hide()
        

    mx.iss.security_groups().then (json) ->
        for group in json
            security_groups[group.name] = group


    query_input.on "focus", onFocus

    query_input.on "blur",  onBlur

    query_input.on "keyup", (event) ->
        query = query_input.val()
        return unless query?
        clearTimeout query_timeout
        query_timeout = _.delay search, search_timeout, query
    
    securities_list_container.on "click", "td[data-secid]", chooseSecurity
    boards_list_container.on "click", "tr[data-param]", chooseTicker
    element.on "click", "td.tag a", closeTag

    

$.extend scope,
    quote_search: widget
