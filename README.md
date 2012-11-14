mimosa-combine
===========

## Overview

This is a Mimosa module for merging a folders contents into a single file. This is an external module and does not come by default with Mimosa.

For more information regarding Mimosa, see http://mimosajs.com

## Usage

Add `'combine'` to your list of modules.  That's all!  Mimosa will install the module for you when you start up.

## Functionality

The `'combine'` module configuration is an array of objects that configure what folders' content to merge, in what order, and where to write the output.

During the 'init' phase of the 'buildDone' workflow, all of the configured combines will be run, and all output files will be created.

During the 'afterWrite' phase of the 'add', 'update', and 'remove' workflows, if any combine folders contain the changed file, those combines will be run.

## Default Config

```
combine:[
  {
    folder:"stylesheets/vendor"
    output:"stylesheets/vendor.css"
    exclude:null
    order:null
  }
]
```

* `combine`: an array of combine configurations
* `folder`: a string, the path to the folder to combine. Path is relative to the watch config settings.
* `output`: a string, the path to the output file result of the combine.  Path is relative to the watch config settings.
* `exclude`: an array of strings, the list of files to exclude from the combine.  Paths should be relative to the watch.compiledDir and should point at the compiled file.  So foo.css, not foo.less. Can be left off or made null if not needed.
* `order`: an array of strings, the list of files to include in the combined file first. Does not need to be all the files, just the files for which order is important.  Paths should be relative to the watch.compiledDir and should point at the compiled file.  So foo.css, not foo.less. Can be left off or made null if not needed.
