##= require underscore

root = @

available_locales   = ['ru', 'en']
default_locale      = available_locales[0]
current_locale      = default_locale

root['mx'] ?= {}


root['mx'].locale = (locale) ->
    current_locale = locale if locale? and _.include(available_locales, locale)
    current_locale


root['mx'].locales =
    number:
        precision:
            format:
                separator:
                    ru: ','
                    en: '.'
                delimiter:
                    ru: ' '
                    en: ','
