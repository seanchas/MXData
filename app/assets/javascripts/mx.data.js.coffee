##= require jquery
##= require underscore
##= require mx.iss
##= require_self
##= require_tree ./mx.data

root = @

root['mx'] ?= {}
root['mx']['data'] = {}

scope = root['mx']['data']

_.extend scope,
    ready: mx.iss.metadata()