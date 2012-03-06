##= require jquery
##= require underscore
##= require_self
##= require_tree ./mx.iss

root = @

root['mx'] ?= {}
root['mx']['iss'] = {}

scope = root['mx']['iss']


merge = (json) ->
    return [] unless json.data? and json.columns?
    for datum in json.data
        item = {}
        for column, index in json.columns
            item[column] = datum[index]
        item
    

$.extend scope,
    url_prefix: 'http://www.beta.micex.ru/iss'
    merge_columns_and_data: merge
