"use strict";
exports.defaults = function() {
  return {
    combine: {
      folders: [],
      removeCombined: {
        enabled: true,
        exclude: [],
        include: []
      }
    }
  };
};

exports.placeholder = function() {
  return "\t\n\n  combine:\n    folders: []      # Configuration for folder combining.  See\n                     # https://github.com/dbashford/mimosa-combine for details on how to set up\n                     # entries in the folders array\n    removeCombined:  # configuration for removing combined files\n      enabled:true   # when set to true, during 'mimosa build' only, mimosa-combine will remove\n                     # the files that were merged into single files\n      exclude:[]     # mimosa-combine will not remove any of these files.\n";
};

exports.validate = function(config, validators) {
  var combine, combines, errorStart, errors, _i, _len;
  errors = [];
  errorStart = "combine.folders";
  if (validators.ifExistsIsObject(errors, "combine", config.combine)) {
    combines = config.combine.folders;
    if (validators.ifExistsIsArray(errors, errorStart, combines)) {
      for (_i = 0, _len = combines.length; _i < _len; _i++) {
        combine = combines[_i];
        if (typeof combine === "object" && !Array.isArray(combine)) {
          if (combine.folder) {
            combine.folder = validators.multiPathNeedNotExist(errors, "" + errorStart + ".folder", combine.folder, config.watch.compiledDir);
          } else {
            errors.push("" + errorStart + " entries must have folder property.");
          }
          if (combine.output != null) {
            combine.output = validators.multiPathNeedNotExist(errors, "combine.output", combine.output, config.watch.compiledDir);
          } else {
            errors.push("" + errorStart + " entries must have output property.");
          }
          if (errors.length > 0) {
            continue;
          }
          validators.ifExistsArrayOfMultiPaths(errors, "" + errorStart + ".order", combine.order, combine.folder);
          if (combine.exclude && combine.include) {
            errors.push("Cannot have both combine.folders.include and combine.folders.exclude");
          } else {
            combine.isExclude = !!combine.exclude;
          }
          validators.ifExistsFileExcludeWithRegexAndString(errors, "" + errorStart + ".exclude", combine, combine.folder);
          if (combine.include) {
            if (validators.ifExistsFileIncludeWithRegexAndString) {
              validators.ifExistsFileIncludeWithRegexAndString(errors, "" + errorStart + ".include", combine, combine.folder);
            } else {
              errors.push("Installed version of Mimosa does not support combine.folders.include. Need Mimosa version 2.3.22 for this feature.");
            }
          }
        } else {
          errors.push("" + errorStart + " must be an array of objects.");
        }
      }
    }
    if (validators.ifExistsIsObject(errors, "combine.removeCombined", config.combine.removeCombined)) {
      validators.ifExistsIsBoolean(errors, "combine.removeCombined.enabled", config.combine.removeCombined.enabled);
      validators.ifExistsFileExcludeWithRegexAndString(errors, "combine.removeCombined.exclude", config.combine.removeCombined, config.watch.compiledDir);
    }
  }
  return errors;
};
