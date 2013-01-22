##= require_self
##= require_tree ./mx.i18n

root                = @

root['mx']         ?= {}
root['mx'].I18n     = {}

i18n                = root['mx'].I18n


# interpolation placeholder
interpolation_placeholder = /(\{\{)(.*?)(\}\})/gm

# locale

i18n.locale = 'en'



# translations

translations = {}


i18n.add_translations = (key, value) ->
    data = {}
    
    key.split('.').reduce((memo, part, i, list) ->
        memo[part]    = if i == list.length - 1 then value else {}
        memo          = memo[part]
        memo
    , data)
    
    $.extend true, translations, data
    
    i18n



# translate

i18n.translate = (scope, options = {}) ->
    
    translation = lookup(scope, options)
    
    try
    
        unless $.type(translation) is 'string'
            if $.isNumeric(options.count)
                pluralize options.count, translation, scope, options
            else
                translation
        else
            interpolate translation, options
    
    catch error
        
        translation_missing scope
        


# lookup

lookup = (scope, options) ->

    messages    = translations[options.locale ? i18n.locale]
    
    [].concat(scope, options.scope).filter((part) -> !!part).join('.').split('.').every (part) -> messages = messages?[part]
    
    messages    = options.default if not messages? and options.default
    
    messages
    


# interpolate

interpolate = (message, options) ->
    
    (message.match(interpolation_placeholder) ? []).forEach (match) ->
        value   = options[match.replace interpolation_placeholder, "$1"] ? "[missing #{match} value]"
        message = message.replace match, value
    
    message



# pluralizations

pluralizations = 

    en: (count) ->
        return ['zero', 'other']    if count == 0
        return 'one'                if count == 1
        return 'other'

    ru: (count) ->
        return ['zero', 'many']     if count == 0
        return 'one'                if count % 10 == 1 and count % 100 != 11
        return 'few'                if [2, 3, 4].indexOf(count % 10) != -1 and [12, 13, 14].indexOf(count % 100) == -1
        return 'many'               if count % 10 == 0 or [5, 6, 7, 8, 9].indexOf(count % 10) != -1 or [11, 12, 13, 14].indexOf(count % 100) != -1
        return 'other'
        


# pluralize

pluralize = (count, messages, scope, options) ->
    
    rules   = pluralizations[options.locale ? i18n.locale] ? pluralizations['en']
    counts  = [].concat rules Math.abs options.count
    count   = counts.filter((count) -> messages[count]?)[0]

    return interpolate(messages[count], options) if count?
    
    translation_missing scope, counts[0]
    
    

# error

translation_missing = (args...) ->
    "[missing #{[].concat(args).join('.')} translation]"
