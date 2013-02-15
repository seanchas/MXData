##= require jquery
##= require underscore
##= require mx.locale
##= require_self
##= require_tree ./mx.iss

root = @

root['mx'] ?= {}
root['mx']['iss'] = {}


scope = root['mx']['iss']

url_prefix  = '/iss'
url_prefix  = mx.url + url_prefix if $.support.cors


merge = (json) ->
    return [] unless json and json.data? and json.columns?
    for datum in json.data
        item = {}
        for column, index in json.columns
            item[column] = datum[index]
        item
    

$.extend scope,
    url_prefix:             url_prefix
    fetch:               -> mx.fetch scope, arguments...
    fetch_descriptors:      {}
    merge_columns_and_data: merge
