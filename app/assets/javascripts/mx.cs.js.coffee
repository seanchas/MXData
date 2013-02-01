##= require jquery
##= require underscore
##= require_self
##= require_tree ./mx.cs

root = @

root['mx'] ?= {}
root['mx']['cs'] = {}

scope = root['mx']['cs']


$.extend scope,
    url_prefix: if $.browser.msie? then '/cs' else 'http://www.beta.micex.ru/cs'
