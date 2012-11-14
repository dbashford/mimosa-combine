"use strict"

fs = require 'fs'
path = require 'path'

exports.defaults = ->
  combine:[
    {
      folder:"stylesheets/vendor"
      output:"stylesheets/vendor.css"
      exclude:null
      order:null
    }
  ]

exports.placeholder = ->
  """
  \t

    # combine: [                           # An array of folder combination details
      # {
        # folder:"stylesheets/vendor"      # The folder to combine into a single file. Path is
                                           # relative to the watch config settings
        # output:"stylesheets/vendor.css"  # The output file for the folder combination. Path is
                                           # relative to the watch config settings
        # exclude:null                     # an array of paths to the files to exclude from
                                           # combining. Paths should be relative to the
                                           # watch.compiledDir and should point at the compiled
                                           # file.  So foo.css, not foo.less. Can be left off or
                                           # made null if not needed.
        # order:null                       # An array of paths to the files to place at the start
                                           # of the merged file.  You do not need to name every
                                           # file, just those whose order is important. Paths
                                           # should be relative to the watch.compiledDir and should
                                           # point at the compiled file.  So foo.css, not foo.less.
                                           # Can be left off or made null if not needed.
      # }
    # ]
  """

exports.validate = (config) ->
  errors = []
  if config.combine?
    if Array.isArray(config.combine)
      for combine in config.combine
        if typeof combine is "object" and not Array.isArray(combine)
          if combine.folder?
            if typeof combine.folder is "string"
              folderPath = path.join config.watch.sourceDir, combine.folder
              unless fs.existsSync folderPath
                errors.push "combine.folder entry [[ #{combine.folder} ]] must resolve to a real path, resolves to [[ #{folderPath} ]]"
            else
              errors.push "combine.folder must be a string"
          else
            errors.push "combine entries must have folder property."

          if combine.output?
            unless typeof combine.output is "string"
              errors.push "combine.output must be a string"
          else
            errors.push "combine entries must have output property."

          if combine.order?
            if Array.isArray(combine.order)
              for order in combine.order
                unless typeof order is "string"
                  errors.push "combine.order must be an array of strings"
                  break
            else
              errors.push "combine.order must be an array"

          if combine.exclude?
            if Array.isArray(combine.exclude)
              for exclude in combine.exclude
                unless typeof exclude is "string"
                  errors.push "combine.exclude must be an array of strings"
                  break
            else
              errors.push "combine.exclude must be an array"
        else
          errors.push "combine must be an array of objects."
    else
      errors.push "combine configuration must be an array."

  if errors.length is 0
    for comb in config.combine

      comb.folder = path.join config.watch.compiledDir, comb.folder
      comb.output = path.join config.watch.compiledDir, comb.output
      if comb.order?
        comb.order = comb.order.map (ord) -> path.join config.watch.compiledDir, ord
      if comb.exclude?
        comb.exclude = comb.exclude.map (exclude) -> path.join config.watch.compiledDir, exclude

  errors
