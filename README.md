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

By default, binary files, like images, are excluded from merging and this cannot be changed.  Other exclusions can be added via the config, as can an order to the files get added.

## Default Config

```
combine:[]
```

## Example Config

If this module had a default config placeholder like other Mimosa modules, it would look something like this:

```
combine: [                           # An array of folder combination details
  {
    folder:"stylesheets/vendor"      # The folder to combine into a single file. Path can
                                       # be relative to the watch config setting, or absolute.
    output:"stylesheets/vendor.css"  # The output file for the folder combination. Path can
                                       # be relative to the watch config setting, or absolute.
    exclude:null                     # An array of regexs or strings that match files to
                                       # exclude from matching. Can be a mix of regex and
                                       # strings. Strings should be a path relative to the
                                       # folder or absolute.
                                       # ex: [/\.txt$/, "vendor/jqueryui.js"], which would keep
                                       # all .txt files and jqueryui.js out of your combined
                                       # file.
    order:null                       # An array of paths to the files to place at the start
                                       # of the merged file.  You do not need to name every
                                       # file, just those whose order is important. Paths
                                       # can be relative to the 'folder' directory or absolute.
                                       # Paths should point at the compiled file. So foo.css,
                                       # not foo.less. Can be left off or made null if not
                                       # needed.
  }
]

```

* `combine`: an array of combine configurations
* `folder`: a string, the path to the folder to combine. Path is relative to the watch config settings.  Path can also be absolute.
* `output`: a string, the path to the output file result of the combine.  Path is relative to the watch config settings.  Path can also be absolute.
* `exclude`: an array of strings and/or regexs, the list of files and file patterns to exclude from the combine.Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Regexes can also be used at the same time.  ex: `ex: [/\.txt$/, "vendor/jqueryui.js"]`. Can be left off or made null if not needed.
* `order`: an array of strings, the list of files to include in the combined file first. Does not need to be all the files, just the files for which order is important. Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Can be left off or made null if not needed.
