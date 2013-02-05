##= require jquery
##= require underscore
##= require d3.v3
##= require mx.iss
##= require mx.i18n
##= require_self
##= require_tree ./mx.data

root = @

root['mx'] ?= {}
root['mx']['data'] = {}

scope = root['mx']['data']


read_or_write_cache = (name, key, value) ->
    cache = kizzy(name)
    if value? then cache.set(key, value) else cache.get(key)


_.extend scope,
    caches:
        table_filtered_columns: _.wrap(read_or_write_cache, (f, key, value) -> f('data.table.filtered_columns', key, value))
        chart_instruments: _.wrap(read_or_write_cache, (f, value) -> f('data.chart.instruments', '', value))
