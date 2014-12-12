"use strict"

fs = require "fs"
path = require "path"

wrench = require 'wrench'
_ = require 'lodash'

config = require './config'

logger = null

registration = (mimosaConfig, register) ->
  logger = mimosaConfig.log

  register ['preClean'],              'init',       _cleanCombined
  register ['add','update','remove'], 'afterWrite', _checkForMerge
  register ['postBuild'],             'init',       _mergeAll

_cleanCombined = (mimosaConfig, options, next) ->
  for combine in mimosaConfig.combine.folders
    if fs.existsSync(combine.output)
      fs.unlinkSync combine.output
      logger.info "mimosa-combine: Deleted file [[ #{combine.output} ]]"
  next()

_checkForMerge = (mimosaConfig, options, next) ->
  return next() unless options.files

  for file in options.files
    fileName = file.outputFileName
    if fileName?
      for combine in mimosaConfig.combine.folders
        if fileName.indexOf(combine.folder) is 0
          if combine.isExclude?
            doit = true
            if combine.exclude? and combine.exclude.indexOf(fileName) isnt -1
              doit = false
            if combine.excludeRegex? and fileName.match(combine.excludeRegex)
              doit = false
          else
            doit = false
            if combine.include? and combine.include.indexOf(fileName) > -1
              doit = true
            if combine.includeRegex? and fileName.match(combine.includeRegex)
              doit = true

          if doit
            __mergeDirectory combine

  next()

_mergeAll = (mimosaConfig, options, next) ->
  combinedFiles = []
  for combine in mimosaConfig.combine.folders
    files = __mergeDirectory combine
    combinedFiles.push files...

  if mimosaConfig.isBuild and mimosaConfig.combine.removeCombined.enabled
    __removeAllCombined combinedFiles, mimosaConfig.combine.removeCombined
    __cleanUpDirectories mimosaConfig.combine.folders

  next()

__transformText = (folderCombineConfig, inputFileName, inputFileText) ->
  transforms = folderCombineConfig.transforms
  if transforms and transforms.length
    outputFileName = folderCombineConfig.output
    for transform in transforms
      transformedText = transform( inputFileText, inputFileName, outputFileName)
      if transformedText is undefined
        logger.error("mimosa-combine transform returned undefined")
      else
        inputFileText = transformedText

  inputFileText

__processIncludeExclude = (combine, folderFiles) ->
  if combine.isExclude
    # remove files mentioned by name
    folderFiles = _.difference(folderFiles, combine.exclude)

    # remove files mentioned by regex
    if combine.excludeRegex
      folderFiles = folderFiles.filter (f) -> not f.match(combine.excludeRegex)
  else
    if combine.include or combine.includeRegex
      includedFiles = []

      # merge in files included via regex
      if combine.includeRegex
        includedFiles = folderFiles.filter (f) -> f.match(combine.includeRegex)

      # merge in files included via string path
      if combine.include
        includedFiles = includedFiles.concat(_.intersection(folderFiles, combine.include))

      folderFiles = includedFiles

  folderFiles

__mergeDirectory = (combine) ->
  unless fs.existsSync combine.folder
    return logger.warn "mimosa-combine: combine folder [[ #{combine.folder} ]] does not exist"

  if logger.isDebug()
    logger.debug "Combining [[ #{combine.folder} ]]"

  if fs.existsSync combine.output
    if logger.isDebug()
      logger.debug "Removing current combined file [[ #{combine.output} ]]"
    fs.unlinkSync combine.output

  # read in all files in folder, remove directories
  folderFiles = wrench.readdirSyncRecursive(combine.folder).map (f) -> path.join combine.folder, f
  folderFiles = folderFiles.filter (f) -> fs.statSync(f).isFile()

  # deal with include/exclude of files from folder
  folderFiles = __processIncludeExclude(combine, folderFiles)

  if folderFiles.length is 0
    logger.info "mimosa-combine: there are no files to combine for configuration"
    return []

  outputFileText = ""
  removeFiles = []

  addFileText = (fileName) ->
    fileText = __getFileText fileName
    if fileText
      transformedText = __transformText combine, fileName, fileText
      outputFileText += transformedText ? ""
    else
      removeFiles.push fileName

  if combine.order?
    folderFiles = _.difference(folderFiles, combine.order)
    combine.order.forEach (orderFile) ->
      if fs.existsSync orderFile
        addFileText orderFile
      else
        logger.warn "mimosa-combine: file listed in combine.order [[ #{orderFile} ]] does not exist"

  folderFiles.forEach addFileText

  unless fs.existsSync path.dirname(combine.output)
    logger.debug "Directory does not exist for combine file [[ #{combine.output} ]], so making it."
    wrench.mkdirSyncRecursive path.dirname(combine.output), 0o0777

  logger.success "mimosa-combine: wrote combined file [[ #{combine.output} ]]"
  fs.writeFileSync combine.output, outputFileText

  # rejoin order files for possible removal
  if combine.order?
    folderFiles = folderFiles.concat combine.order

  # nuke any files that could not be read/understood (binary)
  # as they were not actually included in combine
  folderFiles = _.difference(folderFiles, removeFiles)

  folderFiles

__removeAllCombined = (files, removeCombined) ->

  for file in files
    doit = true
    if removeCombined?.exclude? and removeCombined.exclude.indexOf(file) isnt -1
      doit = false
    if removeCombined?.excludeRegex? and file.match(removeCombined?.excludeRegex)
      doit = false

    if doit and fs.existsSync file
      fs.unlinkSync file
      logger.success "mimosa-combine: removed combined file constituent [[ #{file} ]]"

__cleanUpDirectories = (folders) ->

  for folderConfig in folders
    directories = wrench.readdirSyncRecursive(folderConfig.folder)
      .map((f)-> path.join folderConfig.folder, f)
      .filter((f) -> fs.statSync(f).isDirectory())

    directories.push folderConfig.folder

    _.sortBy(directories, 'length').reverse().forEach (dir) ->
      if fs.existsSync dir
        try
          fs.rmdirSync dir
          logger.success "mimosa-combine: deleted empty combined directory [[ #{dir} ]]"
        catch err
          unless err.code is "ENOTEMPTY"
            logger.error "mimosa-combine: unable to delete combined directory, [[ #{dir} ]]"
            logger.error err

# returns text to add to file
# or returns false if file is binary
__getFileText = (fileName, text) ->
  fileText = fs.readFileSync fileName
  if __getEncoding(fileText) isnt 'binary'
    fileText = fileText.toString('utf8').trim()

    if logger.isDebug()
      logger.debug "Adding [[ #{fileName} ]] to output"

    if path.extname(fileName) is ".js"
      fileText + ";\n"
    else
      fileText + "\n\n"
  else
    if logger.isDebug()
      logger.debug "NOT adding [[ #{fileName} ]] to output"
    false

__getEncoding = (buffer) ->
  contentStartBinary = buffer.toString 'binary', 0, 24
  contentStartUTF8 = buffer.toString 'utf8', 0, 24
  encoding = 'utf8'

  for i in [0...contentStartUTF8.length]
    charCode = contentStartUTF8.charCodeAt(i)
    if charCode is 65533 or charCode <= 8
      # 8 and below are control characters (e.g. backspace, null, eof, etc.)
      # 65533 is the unknown character
      encoding = 'binary'
      break

  encoding

module.exports =
  registration: registration
  defaults:     config.defaults
  placeholder:  config.placeholder
  validate:     config.validate