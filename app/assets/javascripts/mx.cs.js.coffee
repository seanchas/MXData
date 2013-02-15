##= require jquery
##= require underscore
##= require_self
##= require_tree ./mx.cs

root = @

root['mx'] ?= {}
root['mx']['cs'] = {}

scope = root['mx']['cs']

url_prefix  = '/cs'
url_prefix  = mx.url + url_prefix if $.support.cors


$.extend scope,
    url_prefix:             url_prefix
    fetch:               -> mx.fetch scope, arguments...
    fetch_descriptors:      {}
