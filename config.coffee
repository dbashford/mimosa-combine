"use strict"

exports.defaults = ->
  combine:[]

exports.placeholder = ->
  """
  \t

    # combine: []      # Configuration for folder combining.  See
                       # https://github.com/dbashford/mimosa-combine for details on how to set up
                       # entries in the combine array
  """

exports.validate = (config, validators) ->
  errors = []
  if validators.ifExistsIsArray(errors, "combine", config.combine)
    for combine in config.combine
      if typeof combine is "object" and not Array.isArray(combine)

        if combine.folder?
          combine.folder = validators.multiPathNeedNotExist(errors, "combine.folder", combine.folder, config.watch.compiledDir)
        else
          errors.push "combine entries must have folder property."

        if combine.output?
          combine.output = validators.multiPathNeedNotExist(errors, "combine.output", combine.output, config.watch.compiledDir)
        else
          errors.push "combine entries must have output property."

        continue if errors.length > 0

        validators.ifExistsArrayOfMultiPaths(errors, "combine.order", combine.order, combine.folder)
        validators.ifExistsFileExcludeWithRegexAndString(errors, "combine.exclude", combine, combine.folder)
      else
        errors.push "combine must be an array of objects."

  errors