"use strict";
exports.defaults = function() {
  return {
    combine: {
      transforms: [],
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
  return "\t\n\n  combine:\n    transforms:[]    # an array of transform functions to use to alter files\n                     # before they are combined\n    folders: []      # Configuration for folder combining.  See\n                     # https://github.com/dbashford/mimosa-combine for details on how to set up\n                     # entries in the folders array\n    removeCombined:  # configuration for removing combined files\n      enabled:true   # when set to true, during 'mimosa build' only, mimosa-combine will remove\n                     # the files that were merged into single files\n      exclude:[]     # mimosa-combine will not remove any of these files.\n";
};

exports.validate = function(config, validators) {
  var combine, combines, errorStart, errors, transform, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3;
  errors = [];
  errorStart = "combine.folders";
  if (validators.ifExistsIsObject(errors, "combine", config.combine)) {
    if (validators.ifExistsIsArray(errors, "combine.transforms", config.combine.transforms)) {
      _ref = config.combine.transforms;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        transform = _ref[_i];
        if (Object.prototype.toString.call(transform) !== '[object Function]') {
          errors.push("combine.transforms entries must be of type Function");
        }
      }
    }
    combines = config.combine.folders;
    if (validators.ifExistsIsArray(errors, errorStart, combines)) {
      for (_j = 0, _len1 = combines.length; _j < _len1; _j++) {
        combine = combines[_j];
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
          if (validators.ifExistsIsArray(errors, "" + errorStart + ".transforms", combine.transforms)) {
            _ref1 = combine.transforms;
            for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
              transform = _ref1[_k];
              if (Object.prototype.toString.call(transform) !== '[object Function]') {
                errors.push("" + errorStart + ".transforms entries must be of type Function");
              }
            }
          }
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
              errors.push("Installed version of Mimosa does not support combine.folders.include. Need Mimosa version 2.3.22 for this feature. You may want to use older version of mimosa-combine.");
            }
          }
          if (errors.length > 0) {
            continue;
          }
          combine.transforms = ((_ref3 = combine.transforms) != null ? _ref3 : []).concat((_ref2 = config.combine.transforms) != null ? _ref2 : []);
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
