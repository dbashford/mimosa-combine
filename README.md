mimosa-combine
===========

## Overview

This is a Mimosa module for merging a folders contents into a single file. This is an external module and does not come by default with Mimosa.

For more information regarding Mimosa, see http://mimosa.io

## Usage

Add `'combine'` to your list of modules.  That's all!  Mimosa will install the module for you when you start up.

## Functionality

The `'combine'` module configuration contains an array of `folders` that configure what folders' contents to merge, in what order, and where to write the output.

By default, binary files, like images, are excluded from merging and this cannot be configured.  Other exclusions can be added via the config, as can an order to the files get added.

When `mimosa build` is used, by default mimosa-combine cleans up the files it uses to build the combined file.

When `mimosa clean` or `mimosa watch` with the `--clean` flag is run, the `combine` module will clean up the files it has written.

# Config

```javascript
combine: {
  folders: [],
  removeCombined: {
    enabled:true,
    exclude:[]
  }
}
```

# Example Config

```javascript
combine: {
  folders: [{
    folder:"stylesheets/vendor",
    output:"stylesheets/vendor.css",
    exclude:null,
    order:null
  }],
  removeCombined: {
    enabled:true,
    exclude:[]
  }
}
```

* `combine`: root for mimosa-config configuration
* `combine.folders`: array of folders to combine
* `combine.folders.folder`: a string, the path to the folder to combine. Path is relative to the watch config settings.  Path can also be absolute.
* `combine.folders.output`: a string, the path to the output file result of the combine.  Path is relative to the watch config settings.  Path can also be absolute.
* `combine.folders.exclude`: an array of strings and/or regexs, the list of files and file patterns to exclude from the combine.Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Regexes can also be used at the same time.  ex: `ex: [/\.txt$/, "vendor/jqueryui.js"]`. Can be left off or made null if not needed.
* `combine.folders.order`: an array of strings, the list of files to include in the combined file first. Does not need to be all the files, just the files for which order is important. Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Can be left off or made null if not needed.
* `combine.removeCombined`: configuration for cleaning up during a `mimosa build`
* `combine.removeCombined.enabled`: Defaults to `true`, whether or not to clean up the files that went into making the combine files.
* `combine.removeCombined.exclude`: Files to exclude from removal, can be regex or string, strings are relative to the `watch.compiledDir`.
