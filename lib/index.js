"use strict";
var MagicString, config, fs, logger, path, registration, sourceMap, wrench, _, __cleanUpDirectories, __getEncoding, __getFileText, __mergeDirectory, __processIncludeExclude, __removeAllCombined, __transformText, _checkForMerge, _cleanCombined, _mergeAll;

fs = require("fs");

path = require("path");

wrench = require('wrench');

_ = require('lodash');

MagicString = new require('magic-string');

sourceMap = require("convert-source-map");

config = require('./config');

logger = null;

registration = function(mimosaConfig, register) {
  logger = mimosaConfig.log;
  register(['preClean'], 'init', _cleanCombined);
  register(['add', 'update', 'remove'], 'afterWrite', _checkForMerge);
  return register(['postBuild'], 'init', _mergeAll);
};

_cleanCombined = function(mimosaConfig, options, next) {
  var combine, _i, _len, _ref;
  _ref = mimosaConfig.combine.folders;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    combine = _ref[_i];
    if (fs.existsSync(combine.output)) {
      fs.unlinkSync(combine.output);
      logger.info("mimosa-combine: Deleted file [[ " + combine.output + " ]]");
    }
  }
  return next();
};

_checkForMerge = function(mimosaConfig, options, next) {
  var combine, doit, file, fileName, _i, _j, _len, _len1, _ref, _ref1;
  if (!options.files) {
    return next();
  }
  _ref = options.files;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    file = _ref[_i];
    fileName = file.outputFileName;
    if (fileName != null) {
      _ref1 = mimosaConfig.combine.folders;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        combine = _ref1[_j];
        if (fileName.indexOf(combine.folder) === 0) {
          if (combine.isExclude != null) {
            doit = true;
            if ((combine.exclude != null) && combine.exclude.indexOf(fileName) !== -1) {
              doit = false;
            }
            if ((combine.excludeRegex != null) && fileName.match(combine.excludeRegex)) {
              doit = false;
            }
          } else {
            doit = false;
            if ((combine.include != null) && combine.include.indexOf(fileName) > -1) {
              doit = true;
            }
            if ((combine.includeRegex != null) && fileName.match(combine.includeRegex)) {
              doit = true;
            }
          }
          if (doit) {
            __mergeDirectory(mimosaConfig, combine);
          }
        }
      }
    }
  }
  return next();
};

_mergeAll = function(mimosaConfig, options, next) {
  var combine, combinedFiles, files, _i, _len, _ref;
  combinedFiles = [];
  _ref = mimosaConfig.combine.folders;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    combine = _ref[_i];
    files = __mergeDirectory(mimosaConfig, combine);
    combinedFiles.push.apply(combinedFiles, files);
  }
  if (mimosaConfig.isBuild && mimosaConfig.combine.removeCombined.enabled) {
    __removeAllCombined(combinedFiles, mimosaConfig.combine.removeCombined);
    __cleanUpDirectories(mimosaConfig.combine.folders);
  }
  return next();
};

__transformText = function(folderCombineConfig, inputFileName, inputFileText) {
  var outputFileName, transform, transformedText, transforms, _i, _len;
  inputFileText = sourceMap.removeComments(inputFileText);
  transforms = folderCombineConfig.transforms;
  if (transforms && transforms.length) {
    outputFileName = folderCombineConfig.output;
    for (_i = 0, _len = transforms.length; _i < _len; _i++) {
      transform = transforms[_i];
      transformedText = transform(inputFileText, inputFileName, outputFileName);
      if (transformedText === void 0) {
        logger.error("mimosa-combine transform returned undefined");
      } else {
        inputFileText = transformedText;
      }
    }
  }
  return inputFileText;
};

__processIncludeExclude = function(combine, folderFiles) {
  var includedFiles;
  if (combine.isExclude) {
    folderFiles = _.difference(folderFiles, combine.exclude);
    if (combine.excludeRegex) {
      folderFiles = folderFiles.filter(function(f) {
        return !f.match(combine.excludeRegex);
      });
    }
  } else {
    if (combine.include || combine.includeRegex) {
      includedFiles = [];
      if (combine.includeRegex) {
        includedFiles = folderFiles.filter(function(f) {
          return f.match(combine.includeRegex);
        });
      }
      if (combine.include) {
        includedFiles = includedFiles.concat(_.intersection(folderFiles, combine.include));
      }
      folderFiles = includedFiles;
    }
  }
  return folderFiles;
};

__mergeDirectory = function(mimosaConfig, combine) {
  var addFileText, bundle, bundleOutput, comment, converter, folderFiles, map, removeFiles;
  if (!fs.existsSync(combine.folder)) {
    return logger.warn("mimosa-combine: combine folder [[ " + combine.folder + " ]] does not exist");
  }
  if (logger.isDebug()) {
    logger.debug("Combining [[ " + combine.folder + " ]]");
  }
  if (fs.existsSync(combine.output)) {
    if (logger.isDebug()) {
      logger.debug("Removing current combined file [[ " + combine.output + " ]]");
    }
    fs.unlinkSync(combine.output);
  }
  folderFiles = wrench.readdirSyncRecursive(combine.folder).map(function(f) {
    return path.join(combine.folder, f);
  });
  folderFiles = folderFiles.filter(function(f) {
    return fs.statSync(f).isFile();
  });
  folderFiles = __processIncludeExclude(combine, folderFiles);
  if (folderFiles.length === 0) {
    logger.info("mimosa-combine: there are no files to combine for configuration");
    return [];
  }
  removeFiles = [];
  bundle = new MagicString.Bundle();
  addFileText = function(fileName) {
    var appendText, fileText, transformedText;
    fileText = __getFileText(fileName);
    if (fileText) {
      transformedText = __transformText(combine, fileName, fileText);
      appendText = "\n\n";
      if (path.extname(fileName) === ".js") {
        appendText = ";\n";
      }
      return bundle.addSource({
        filename: fileName,
        content: new MagicString(transformedText != null ? transformedText : "").append(appendText)
      });
    } else {
      return removeFiles.push(fileName);
    }
  };
  if (combine.order != null) {
    folderFiles = _.difference(folderFiles, combine.order);
    combine.order.forEach(function(orderFile) {
      if (fs.existsSync(orderFile)) {
        return addFileText(orderFile);
      } else {
        return logger.warn("mimosa-combine: file listed in combine.order [[ " + orderFile + " ]] does not exist");
      }
    });
  }
  folderFiles.forEach(addFileText);
  if (!fs.existsSync(path.dirname(combine.output))) {
    logger.debug("Directory does not exist for combine file [[ " + combine.output + " ]], so making it.");
    wrench.mkdirSyncRecursive(path.dirname(combine.output), 0x1ff);
  }
  logger.success("mimosa-combine: wrote combined file [[ " + combine.output + " ]]");
  bundleOutput = bundle.toString();
  if (mimosaConfig.combine.sourceMap && !mimosaConfig.isBuild) {
    map = bundle.generateMap({
      file: combine.output,
      includeContent: true,
      hires: true
    });
    converter = sourceMap.fromObject(map);
    comment = converter.toComment();
    bundleOutput += "\n/*#" + comment.slice(3) + "*/";
  }
  fs.writeFileSync(combine.output, bundleOutput);
  if (combine.order != null) {
    folderFiles = folderFiles.concat(combine.order);
  }
  folderFiles = _.difference(folderFiles, removeFiles);
  return folderFiles;
};

__removeAllCombined = function(files, removeCombined) {
  var doit, file, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = files.length; _i < _len; _i++) {
    file = files[_i];
    doit = true;
    if (((removeCombined != null ? removeCombined.exclude : void 0) != null) && removeCombined.exclude.indexOf(file) !== -1) {
      doit = false;
    }
    if (((removeCombined != null ? removeCombined.excludeRegex : void 0) != null) && file.match(removeCombined != null ? removeCombined.excludeRegex : void 0)) {
      doit = false;
    }
    if (doit && fs.existsSync(file)) {
      fs.unlinkSync(file);
      _results.push(logger.success("mimosa-combine: removed combined file constituent [[ " + file + " ]]"));
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

__cleanUpDirectories = function(folders) {
  var directories, folderConfig, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = folders.length; _i < _len; _i++) {
    folderConfig = folders[_i];
    directories = wrench.readdirSyncRecursive(folderConfig.folder).map(function(f) {
      return path.join(folderConfig.folder, f);
    }).filter(function(f) {
      return fs.statSync(f).isDirectory();
    });
    directories.push(folderConfig.folder);
    _results.push(_.sortBy(directories, 'length').reverse().forEach(function(dir) {
      var err;
      if (fs.existsSync(dir)) {
        try {
          fs.rmdirSync(dir);
          return logger.success("mimosa-combine: deleted empty combined directory [[ " + dir + " ]]");
        } catch (_error) {
          err = _error;
          if (err.code !== "ENOTEMPTY") {
            logger.error("mimosa-combine: unable to delete combined directory, [[ " + dir + " ]]");
            return logger.error(err);
          }
        }
      }
    }));
  }
  return _results;
};

__getFileText = function(fileName, text) {
  var fileText;
  fileText = fs.readFileSync(fileName);
  if (__getEncoding(fileText) !== 'binary') {
    if (logger.isDebug()) {
      logger.debug("Adding [[ " + fileName + " ]] to output");
    }
    return fileText.toString('utf8').trim();
  } else {
    if (logger.isDebug()) {
      logger.debug("NOT adding [[ " + fileName + " ]] to output");
    }
    return false;
  }
};

__getEncoding = function(buffer) {
  var charCode, contentStartBinary, contentStartUTF8, encoding, i, _i, _ref;
  contentStartBinary = buffer.toString('binary', 0, 24);
  contentStartUTF8 = buffer.toString('utf8', 0, 24);
  encoding = 'utf8';
  for (i = _i = 0, _ref = contentStartUTF8.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
    charCode = contentStartUTF8.charCodeAt(i);
    if (charCode === 65533 || charCode <= 8) {
      encoding = 'binary';
      break;
    }
  }
  return encoding;
};

module.exports = {
  registration: registration,
  defaults: config.defaults,
  placeholder: config.placeholder,
  validate: config.validate
};
