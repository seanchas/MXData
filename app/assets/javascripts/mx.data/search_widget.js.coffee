root    = @
scope   = root['mx']['data']
$       = jQuery

# iss dummy data

filters_data = [
  { name: "Все рынки",      value: "all"      }
  { name: "Индексы",        value: "indecex"  }
  { name: "Фондовый рынок", value: "stock"    }
  { name: "Валютный рынок", value: "currency" }
]

search_results_data = []
results_groups_data = []

DummyData =
  filters: [
    { name: "Индексы",        value: "indecex"  }
    { name: "Фондовый рынок", value: "stock"    }
    { name: "Валютный рынок", value: "currency" }
  ]




# configuration
tip_content                  = "Введите наименование инструмента или эмитента, например: <em>Сбербанк</em> или <em>GAZP</em>"
query_input_placeholder      = "Поиск"
search_field_param_threshold = 3
input_timeout_in_ms          = 1500

AppConfig =
  default_filter:
    name:  "Все рынки"
    value: "all"
  query_input_placeholder: "Поиск"
  query_input_threshold:   3
  input_timeout_in_ms:     1500


default_filter =
  name:  "Все рынки"
  value: "all"

default_mode_selector =
  label:   "Искать только в основном режиме"
  value:  "only_main"
  checked: true


#
#  FilterChooser
#

class FilterChooser
  constructor: (@_el, @_list, @options = {}) ->

    @_filters = []
    @_current = @options.default_filter || AppConfig.default_filter
    @_filters.push(@_current)

    @_el     = $(@_el);   return unless @_el
    @_list   = $(@_list); return unless @_list

    @_el.addClass("filter_chooser")

    @_view   = new FiltersListView(@_list, @)
    @_is_exposed = false

    @render()
    @_filters = $.merge @_filters, @requestFilters()
    @_view.setFiltersList(@_filters, 0)

    @startEventListeners()

  render: ->
    @_el.html(@_current.name)

  requestFilters: ->
    # iss request must be
    DummyData.filters

  setCurrentFilterByIndex: (index) ->
    @_current = @_filters[index]
    @render()
    @_view.select(index)

  toggleState: ->
    if @_is_exposed then @unexpose() else @expose()

  unexpose: ->
    @_el.removeClass "active"
    @_view.hide()
    @_is_exposed = false

  expose: ->
    @_el.addClass "active"
    @_view.show()
    @_is_exposed = true

  startEventListeners: ->
    @_el.on "click", () =>
      @toggleState()

  el: ->
    @_el

#
#  Filters List View
#
class FiltersListView
  constructor: (@_el, @_chooser) ->
    @_el = $(@_el);   return unless @_el
    @_el.addClass("filters_list")

    position     = @_chooser.el().offset()
    position.top = @_chooser.el().outerHeight() + position.top

    @_el.offset(position)
    @startEventListeners()
    @_el.hide()

  render: ->
    return unless @_filters

    @_el.html ""

    $.map @_filters, (el, index) =>
      li    = $("<li>").addClass("filter")
      input = $("<input>").attr("type", "radio").attr("value", el.value).attr("name", "filter").attr("id", "filter_#{el.value}")
      if index == @_index
        input.attr "checked", true
        li.addClass "active"
      li.append input
      label = $("<label for=\"filter_#{el.value}\">").html(el.name)
      li.append label
      @_el.append(li)

  setFiltersList: (filters) ->
    @_filters  = filters
    @_index    = 0
    @render()

  select: (index) ->
    items = @_el.find("li")
    radio_btns = @_el.find("input")

    $(radio_btns[@_index]).attr("checked", false)
    $(items[@_index]).removeClass("active")

    $(radio_btns[index]).attr("checked", true)
    $(items[index]).addClass("active")

    @_index = index

  show: ->
    @_el.slideDown(250)

  hide: ->
    @_el.slideUp(250)

  startEventListeners: ->
    $(".filter").live "click", (e) =>
      index = $(e.currentTarget).prevAll().size()
      @select(index)
      @_chooser.setCurrentFilterByIndex(index)


#
#  QueryInput
#

class QueryInput
  constructor: (@_el, @_el_results) ->

    @_el         = $(@_el);         return unless @_el
    @_el_results = $(@_el_results); return unless @_el_results

    @_input = $("<input>").addClass("query_input").attr("type", "search")
    @_input.attr("placeholder", AppConfig.query_input_placeholder)

    @_el.addClass("query_input_wrapper")
    @_el.append(@_input)

    @_query_string = ""

    @startEventListeners()

  startEventListeners: ->
    @_input.on "keyup click", (e) =>
      string = @_input.attr "value"
      if string.length > AppConfig.query_input_threshold and string != @_query_string
        @search(string)
        @_query_string = string

  search: (query)->
    console.log(query)


#
#  SearchWidget
#
class SearchWidget
  constructor: (@element, @options = {}) ->
    @prepare()

  prepare: ->
    @render()
    @query_input    = new QueryInput(@_containers.query_input, @_contain)
    @filter_chooser = new FilterChooser(@_containers.filter_chooser, @_containers.filters_list)
    #@hide()

  render: ->
    @element.addClass("search_widget")

    @_containers ||= {}

    @_containers.filter_chooser = $("<span>")
    @_containers.filters_list   = $("<ul>")

    @_containers.tip            = @renderTip()
    @_containers.query_input    = $("<div>")

    @element.append @_containers.query_input
    @element.append @_containers.filter_chooser
    @element.after  @_containers.filters_list

    @_containers.mode_selector  = @renderModeSelector()
    @_containers.search_results = @renderSearchResults()
    @_containers.results_groups = @renderResultsGroups()

  renderTip: ->
    tip = $("<p>")
    tip.addClass("tip")
    tip.html(tip_content)
    @element.append(tip)
    tip

  renderModeSelector: ->
    mode_selector = $("<p>")
    mode_selector.addClass("mode_selector")
    checkbox = $("<input>")
    checkbox.attr("type", "checkbox")
    checkbox.attr("id",   "mode_selector")
    checkbox.attr("checked", "checked") if default_mode_selector.checked
    checkbox.attr("value", default_mode_selector.value)
    label = $("<label>")
    label.attr("for", "mode_selector")
    label.html(default_mode_selector.label)
    mode_selector.append(checkbox)
    mode_selector.append(label)
    @element.append(mode_selector)
    mode_selector

  renderSearchResults: ->
    search_results = $("<div>")
    search_results.addClass("search_results")
    @element.after(search_results)
    search_results

  renderResultsGroups: ->
    results_groups = $("<ul>")
    results_groups.addClass("results_groups")
    @element.after(results_groups)
    results_groups

  show: ->
    @element.show()

  hide: ->
    @element.hide()
    @_containers.search_results.hide()
    @_containers.results_groups.hide()



widget = (element, options = {}) ->
  element = $(element); return unless _.size(element) > 0
  new SearchWidget(element);



$.extend scope,
  search_widget: widget
