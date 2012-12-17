"use strict"

fs = require "fs"
path = require "path"
wrench = require 'wrench'
_ = require 'lodash'
logger = require 'logmimosa'

config = require './config'

registration = (mimosaConfig, register) ->
  register ['preClean'], 'init', _cleanCombined
  register ['add','update','remove'], 'afterWrite', _checkForMerge
  register ['postBuild'], 'init', _mergeAll

_cleanCombined = (mimosaConfig, options, next) ->
  for combine in mimosaConfig.combine
    if fs.existsSync(combine.output)
      fs.unlinkSync(combine.output)
      logger.info "mimosa-combine: Deleted file [[ #{combine.output} ]]"
  next()

_checkForMerge = (mimosaConfig, options, next) ->
  for file in options.files
    fileName = file.outputFileName
    if fileName?
      for combine in mimosaConfig.combine
        if fileName.indexOf(combine.folder) is 0
          doit = true
          if combine.exclude? and combine.exclude.indexOf(fileName) isnt -1
            doit = false
          if combine.excludeRegex? and fileName.match(combine.excludeRegex)
            doit = false
          __mergeDirectory combine if doit
  next()

_mergeAll = (mimosaConfig, options, next) ->
  for combine in mimosaConfig.combine
    __mergeDirectory combine
  next()

__mergeDirectory = (combine) ->
  logger.debug "Combining [[ #{combine.folder} ]]"

  if fs.existsSync combine.output
    logger.debug "Removing current combined file [[ #{combine.output} ]]"
    fs.unlinkSync combine.output

  folderFiles = wrench.readdirSyncRecursive(combine.folder).map (f) -> path.join combine.folder, f
  folderFiles = folderFiles.filter (f) -> fs.statSync(f).isFile()
  folderFiles = _.difference(folderFiles, combine.exclude)
  if combine.excludeRegex
    folderFiles = folderFiles.filter (f) -> not f.match(combine.excludeRegex)

  outputFileText = ""

  if combine.order?
    folderFiles = _.difference(folderFiles, combine.order)
    combine.order.forEach (orderFile) ->
      if fs.existsSync orderFile
        outputFileText += __addFileToText(orderFile)
      else
        logger.warn "File listed in combine.order [[ #{orderFile} ]] does not exist"

  folderFiles.forEach (folderFile) ->
    outputFileText += __addFileToText(folderFile)

  unless fs.existsSync path.dirname(combine.output)
    logger.debug "Directory does not exist for combine file [[ #{combine.output} ]], so making it."
    wrench.mkdirSyncRecursive path.dirname(combine.output), 0o0777

  logger.success "Writing combined file [[ #{combine.output} ]]"
  fs.writeFileSync combine.output, outputFileText

__addFileToText = (fileName, text) ->
  fileText = fs.readFileSync(fileName)
  if __getEncoding(fileText) isnt 'binary'
    logger.debug "Adding [[ #{fileName} ]] to output"
    if path.extname(fileName) is ".js"
      fileText + ";"
    else
      fileText + "\n"
  else
    logger.debug "NOT adding [[ #{fileName} ]] to output"
    ""

__getEncoding = (buffer) ->
  contentStartBinary = buffer.toString('binary',0,24)
  contentStartUTF8 = buffer.toString('utf8',0,24)
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