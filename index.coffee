"use strict"

fs = require "fs"
path = require "path"
wrench = require 'wrench'
_ = require 'lodash'
logger = require 'logmimosa'

config = require './config'

registration = (mimosaConfig, register) ->
  register ['add','update','remove'], 'afterWrite', _checkForMerge
  register ['buildDone'], 'init', _mergeAll

_checkForMerge = (mimosaConfig, options, next) ->
  for file in options.files
    fileName = file.outputFileName
    if fileName?
      for combine in mimosaConfig.combine
        if fileName.indexOf(combine.folder) is 0
          __mergeDirectory(combine)
  next()

_mergeAll = (mimosaConfig, options, next) ->
  for combine in mimosaConfig.combine
    __mergeDirectory(combine)
  next()

__mergeDirectory = (combine) ->
  logger.debug "Combining [[ #{combine.folder} ]]"

  if fs.existsSync combine.output
    logger.debug "Removing current combined file [[ #{combine.output} ]]"
    fs.unlinkSync combine.output

  folderFiles = wrench.readdirSyncRecursive(combine.folder).map (f) -> path.join combine.folder, f
  folderFiles = folderFiles.filter (f) -> fs.statSync(f).isFile()
  folderFiles = _.difference(folderFiles, combine.exclude)

  outputFileText = ""

  if combine.order?
    folderFiles = _.difference(folderFiles, combine.order)
    combine.order.forEach (orderFile) ->
      if fs.existsSync orderFile
        logger.debug "Adding [[ #{orderFile} ]] to [[ #{combine.output} ]] in appropriate order"
        outputFileText += fs.readFileSync(orderFile) + "\n"
      else
        logger.warn "File listed in combine.order [[ #{orderFile} ]] does not exist"

  folderFiles.forEach (folderFile) ->
    logger.debug "Adding [[ #{folderFile} ]] to [[ #{combine.output} ]]"
    outputFileText += fs.readFileSync(folderFile) + "\n"

  unless fs.existsSync path.dirname(combine.output)
    logger.debug "Directory does not exist for combine file [[ #{combine.output} ]], so making it."
    wrench.mkdirSyncRecursive path.dirname(combine.output), 0o0777

  logger.success "Writing combined file [[ #{combine.output} ]]"
  fs.writeFileSync combine.output, outputFileText

module.exports =
  registration: registration
  defaults:     config.defaults
  placeholder:  config.placeholder
  validate:     config.validate