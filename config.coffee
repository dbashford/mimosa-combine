"use strict"

fs = require 'fs'
path = require 'path'

windowsDrive = /^[A-Za-z]:\\/

exports.defaults = ->
  combine:[]

exports.placeholder = ->
  """
  \t

    # combine: []      # Configuration for folder combining.  See
                       # https://github.com/dbashford/mimosa-combine for details on how to set up
                       # entries in the combine array
  """

exports.validate = (config) ->
  errors = []
  if config.combine?
    if Array.isArray(config.combine)
      for combine in config.combine
        if typeof combine is "object" and not Array.isArray(combine)


          if combine.folder?
            if typeof combine.folder is "string"
              folderPath = __determinePath combine.folder, config.watch.sourceDir
              if fs.existsSync folderPath
                combine.folder = __determinePath combine.folder, config.watch.compiledDir
              else
                errors.push "combine.folder entry [[ #{combine.folder} ]] must resolve to a real path, resolves to [[ #{folderPath} ]]"
            else
              errors.push "combine.folder must be a string"
          else
            errors.push "combine entries must have folder property."


          if combine.output?
            if typeof combine.output is "string"
              combine.output = __determinePath combine.output, config.watch.compiledDir
            else
              errors.push "combine.output must be a string"
          else
            errors.push "combine entries must have output property."


          continue if errors.length > 0


          if combine.order?
            if Array.isArray(combine.order)
              newOrder = []
              folderPath = __determinePath combine.folder, config.watch.sourceDir
              for order in combine.order
                if typeof order is "string"
                  newOrder.push __determinePath order, combine.folder
                else
                  errors.push "combine.order must be an array of strings."
                  break
              combine.order = newOrder
            else
              errors.push "combine.order must be an array."


          if combine.exclude?
            if Array.isArray(combine.exclude)
              regexes = []
              newExclude = []
              for exclude in combine.exclude
                if typeof exclude is "string"
                  newExclude.push __determinePath exclude, combine.folder
                else if exclude instanceof RegExp
                  regexes.push exclude.source
                else
                  errors.push "combine.exclude must be an array of strings and/or regexes."
                  break

              if regexes.length > 0
                combine.excludeRegex = new RegExp regexes.join("|"), "i"

              combine.exclude = newExclude
            else
              errors.push "combine.exclude must be an array"
        else
          errors.push "combine must be an array of objects."
    else
      errors.push "combine configuration must be an array."

  errors

__determinePath = (thePath, relativeTo) ->
  return thePath if windowsDrive.test thePath
  return thePath if thePath.indexOf("/") is 0
  path.join relativeTo, thePath
