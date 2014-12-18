"use strict"

exports.defaults = ->
  combine:
    sourceMap: true
    transforms:[]
    folders: []
    removeCombined:
      enabled:true
      exclude:[]
      include:[]

exports.placeholder = ->
  """
  \t

    combine:
      sourceMap: true  # whether or not to generate a source map during developmen
                       # (mimosa watch, not build)
      transforms:[]    # an array of transform functions to use to alter files
                       # before they are combined
      folders: []      # Configuration for folder combining.  See
                       # https://github.com/dbashford/mimosa-combine for details on how to set up
                       # entries in the folders array
      removeCombined:  # configuration for removing combined files
        enabled:true   # when set to true, during 'mimosa build' only, mimosa-combine will remove
                       # the files that were merged into single files
        exclude:[]     # mimosa-combine will not remove any of these files.

  """

exports.validate = (config, validators) ->
  errors = []

  errorStart = "combine.folders"

  if validators.ifExistsIsObject(errors, "combine", config.combine)

    validators.ifExistsIsBoolean(errors, "combine.sourceMap", config.combine.sourceMap)

    if validators.ifExistsIsArray(errors, "combine.transforms", config.combine.transforms)
      for transform in config.combine.transforms
        if Object.prototype.toString.call(transform) isnt '[object Function]'
          errors.push "combine.transforms entries must be of type Function"

    combines = config.combine.folders
    if validators.ifExistsIsArray(errors, errorStart, combines)
      for combine in combines
        if typeof combine is "object" and not Array.isArray(combine)

          if combine.folder
            combine.folder = validators.multiPathNeedNotExist(errors, "#{errorStart}.folder", combine.folder, config.watch.compiledDir)
          else
            errors.push "#{errorStart} entries must have folder property."

          if combine.output?
            combine.output = validators.multiPathNeedNotExist(errors, "combine.output", combine.output, config.watch.compiledDir)
          else
            errors.push "#{errorStart} entries must have output property."

          continue if errors.length > 0

          validators.ifExistsArrayOfMultiPaths(errors, "#{errorStart}.order", combine.order, combine.folder)

          if validators.ifExistsIsArray(errors, "#{errorStart}.transforms", combine.transforms)
            for transform in combine.transforms
              if Object.prototype.toString.call(transform) isnt '[object Function]'
                errors.push "#{errorStart}.transforms entries must be of type Function"

          if combine.exclude and combine.include
            errors.push "Cannot have both combine.folders.include and combine.folders.exclude"
          else
            combine.isExclude = !!combine.exclude

          validators.ifExistsFileExcludeWithRegexAndString(errors, "#{errorStart}.exclude", combine, combine.folder)
          if combine.include
            if validators.ifExistsFileIncludeWithRegexAndString
              validators.ifExistsFileIncludeWithRegexAndString(errors, "#{errorStart}.include", combine, combine.folder)
            else
              errors.push "Installed version of Mimosa does not support combine.folders.include. Need Mimosa version 2.3.22 for this feature. You may want to use older version of mimosa-combine."

          continue if errors.length > 0

          combine.transforms = (combine.transforms ? []).concat( config.combine.transforms ? [] )

        else
          errors.push "#{errorStart} must be an array of objects."

    if validators.ifExistsIsObject(errors, "combine.removeCombined", config.combine.removeCombined)

      validators.ifExistsIsBoolean(errors, "combine.removeCombined.enabled", config.combine.removeCombined.enabled)
      validators.ifExistsFileExcludeWithRegexAndString(errors, "combine.removeCombined.exclude", config.combine.removeCombined, config.watch.compiledDir)

  errors
