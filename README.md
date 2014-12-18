mimosa-combine
===========

## Overview

This is a Mimosa module for merging a folders contents into a single file. This is an external module and does not come by default with Mimosa.

For more information regarding Mimosa, see http://mimosa.io

NOTE: Version `2.0.0`+ of mimosa-combine requires Mimosa version `2.3.22` or higher. If you cannot update mimosa to that version, you will want to pin the mimosa-combine version to `1.0.2`.  Update your `modules` list to contain `combine@1.0.2` instead of just `combine`.

## Usage

Add `'combine'` to your list of modules.  That's all!  Mimosa will install the module for you when you start up.

## Functionality

The `'combine'` module configuration contains an array of `folders` that configure what folders' contents to merge, in what order, and where to write the output.

By default, binary files, like images, are excluded from merging and this cannot be configured.  Other exclusions can be added via the config, as can an order to the files get added.

If inline source maps are in a file that is being combined, they will be removed.  The module has the ability to add its own source maps and it will add them by default during `mimosa watch`.  Source maps are turned off during `mimosa build`.

When `mimosa build` is used, by default mimosa-combine cleans up the files it uses to build the combined file.

When `mimosa clean` or `mimosa watch` with the `--clean` flag is run, the `combine` module will clean up the files it has written.

# Default Config

```javascript
combine: {
  sourceMap: true,
  folders: [],
  transforms:[],
  removeCombined: {
    enabled:true,
    exclude:[]
  }
}
```

The default config is empty. This module will not do anything unless folders are configured.

# Example Folder Config

```javascript
combine: {
  folders: [{
    folder:"stylesheets/vendor",
    output:"stylesheets/vendor.css",
    exclude:null,
    include:null,
    order:null,
    transforms:[
      function(inputText,inputName,outputName) {
        // transform text
        return transformedText;
      }
    ]
  }]
}
```

* `combine`: root for mimosa-config configuration
* `combine.sourceMap`: whether or not to generate source maps for combined files. This will not take into account any manipulations made by any transform functions, and it will not use existing source maps.  Existing source maps are automatically stripped as they serve no purpose in a combined situation.
* `combine.folders`: array of folders to combine
* `combine.folders.folder`: a string, the path to the folder to combine. Path is relative to the watch config settings.  Path can also be absolute.
* `combine.folders.output`: a string, the path to the output file result of the combine.  Path is relative to the watch config settings.  Path can also be absolute.
* `combine.folders.exclude`: an array of strings and/or regexs, the list of files and file patterns to exclude from the combine. Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Regexes can also be used at the same time.  ex: `ex: [/\.txt$/, "vendor/jqueryui.js"]`. Can be left off or made `null` if not needed.  Note: `include` and `exclude` are exclusive.  If you have configured both, mimosa will error out during startup with validation errors.
* `combine.folders.include`: an array of strings and/or regexs, the list of files and file patterns to include in the combine. Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Regexes can also be used at the same time.  ex: `ex: [/\.txt$/, "vendor/jqueryui.js"]`. Can be left off or made `null` if not needed.  Note: `include` and `exclude` are exclusive.  If you have configured both, mimosa will error out during startup with validation errors.
* `combine.folders.order`: an array of strings, the list of files to include in the combined file first. Does not need to be all the files, just the files for which order is important. Paths should be relative to `folder` and should point at the compiled file. So foo.css, not foo.less. Can be left off or made null if not needed.
* `combine.folders.transforms`: See [Transform Functions]() below. Transform functions provided at the `folders` level are applied to only the files being merged for this folder.
* `combine.transforms`: See [Transform Functions]() below. Top level transform functions are applied to all `combine.folders` entries.
* `combine.removeCombined`: configuration for cleaning up during a `mimosa build`
* `combine.removeCombined.enabled`: Defaults to `true`, whether or not to clean up the files that went into making the combine files.
* `combine.removeCombined.exclude`: Files to exclude from removal, can be regex or string, strings are relative to the `watch.compiledDir`.

# Transform Functions

Both with `combine.transforms` and `combine.folders.transforms` you are able to use functions provided via the config to transform the text of files being combined.

Why would you want to do this? Lets say you have a folder structure that looks like this:

```
/assets
  /stylesheets
    /vendor
      /leaflet.draw
        leaflet.draw.css
        /images
          spritesheet.png
```

And lets say you want to combine all vendor stylesheets into a `/public/stylesheets/vendor.css` file.  So your `leaflet.draw.css` ends up combined inside `vendor.css`.  `spritesheet.png` is obviously not combined because it is binary.  So your `/public` directory structure looks like this:

```
/public
  /stylesheets
    vendor.css
    /vendor
      /leaflet.draw
        /images
           spritesheet.png
```

Purposefully it was decided not to JUST COPY the spritesheet into the same location as the combined file.  Leaflet plugins, for example, tend to always have spritesheets named `spritesheet.png`, which means they cannot all exist in the same directory.  It is best to keep them apart.

`leaflet.draw.css` has references to the `spritesheet.png` inside of it.  References that are now broken because the paths no longer resolve.

```css
.leaflet-draw-toolbar a {
  background-image: url('images/spritesheet.png');
  background-repeat: no-repeat;
}
```

A transform function can take care of this.  It can parse the text to find the paths and then alter them.

## How to use/create a transform function

Both `combine.transforms` and `combine.folders.transforms` can take an array of transform functions.  These functions are passed three parameters and must returned the transformed text

```javascript
var transformFunction = function( inputText, inputFileName, outputFileName) {
  // transform the text
  return transformedText;
}
```

* `inputText` is the text of the file being processed, it is the contents of a file that is going to be combined
* `inputFileName` is the name of the file being processed from inside the `watch.compiledDir`
* `outputFileName` is the name of the combined output file where the input file is going to end up.

You can provide functions directly in-line, but it is recommended you keep transforms someplace outside the config and `require` them in.

```javascript
transforms:[require('./scripts/transformX')]
```

Soon there will be transforms available in NPM that you can include in the `package.json` of your project and `require` in directly.
