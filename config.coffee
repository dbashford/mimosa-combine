"use strict"

logger = require 'logmimosa'

exports.defaults = ->
  combine:
    folders: []
    removeCombined:
      enabled:true
      exclude:[]

exports.placeholder = ->
  """
  \t

    # combine:
      # folders: []      # Configuration for folder combining.  See
                         # https://github.com/dbashford/mimosa-combine for details on how to set up
                         # entries in the folders array
      # removeCombined:  # configuration for removing combined files
        # enabled:true   # when set to true, during 'mimosa build' only, mimosa-combine will remove
                         # the files that were merged into single files
        # exclude:[]     # mimosa-combine will not remove any of these files.

  """

exports.validate = (config, validators) ->
  errors = []

  errorStart = "combine.folders"
  if Array.isArray(config.combine)
    logger.warn """
      You are using a deprecated configuration for mimosa-combine, which is, for now, still supported.
      In 0.11.0 support for combine:[] will be removed. The new config takes the form: #{exports.placeholder()}
      where combine.folders:[] is the old combine:[].\n
    """

    combines = config.combine
    config.combine = exports.defaults()
    config.combine.folders = combines
    config.combine.removeCombined.enabled = false
    errorStart = "combine"

  combines = config.combine.folders

  if validators.ifExistsIsObject(errors, "combine", config.combine)
    if validators.ifExistsIsArray(errors, errorStart, combines)
      for combine in combines
        if typeof combine is "object" and not Array.isArray(combine)

          if combine.folder?
            combine.folder = validators.multiPathNeedNotExist(errors, "#{errorStart}.folder", combine.folder, config.watch.compiledDir)
          else
            errors.push "#{errorStart} entries must have folder property."

          if combine.output?
            combine.output = validators.multiPathNeedNotExist(errors, "combine.output", combine.output, config.watch.compiledDir)
          else
            errors.push "#{errorStart} entries must have output property."

          continue if errors.length > 0

          validators.ifExistsArrayOfMultiPaths(errors, "#{errorStart}.order", combine.order, combine.folder)
          validators.ifExistsFileExcludeWithRegexAndString(errors, "#{errorStart}.exclude", combine, combine.folder)
        else
          errors.push "#{errorStart} must be an array of objects."

    if validators.ifExistsIsObject(errors, "combine.removeCombined", config.combine.removeCombined)

      validators.ifExistsIsBoolean(errors, "combine.removeCombined.enabled", config.combine.removeCombined.enabled)
      validators.ifExistsFileExcludeWithRegexAndString(errors, "combine.removeCombined.exclude", config.combine.removeCombined, config.watch.compiledDir)

  errors