"use strict";
require! {
  through2
  LiveScript
  path: Path
  "gulp-util": gutil
}

module.exports = (options) ->
  through2.obj(
    new VinylLSConverter(options || {}).transformFn
  )

/* jshint -W004 */
/* jshint -W014 */
/* jshint -W030 */
/* jshint -W033 */
/* jshint -W116 */
class VinylLSConverter
  (@options) ->
    @isJson = delete options.json

  transformFn: !(file, enc, done) ~>
    [error, clonedFile] = @_convert(file)
    error = new gutil.PluginError "gulp-livescript", error if error
    done(error, clonedFile)

  _convert: (file) ->
    if file.isNull!
      [null, file]
    else if file.isStream!
      ["Streaming not supported", null]
    else if '.js' is Path.extname file.path
      [null, file]
    else
      @_tryConvertToJS(file.clone!)

  _tryConvertToJS: (clonedFile) ->
    try
      json = @_convertFilepath(clonedFile)
      input = clonedFile.contents.toString("utf8")
      options = {} <<< @options
      options.bare ||= json

      tokens = LiveScript.tokens(input, raw: options.lex)
      ast = LiveScript.ast(tokens)
      ast.make-return! if json
      output = ast.compile-root(options)

      if json
        result = LiveScript.run(output, options, true)
        output = JSON.stringify(result, null, 2) + "\n"

      clonedFile.contents = new Buffer(output)
    catch error
      error.message += "\nat " + clonedFile.path
      clonedFile = null
    [error, clonedFile]

  _convertFilepath: (clonedFile) ->
    dirname = Path.dirname(clonedFile.path)
    filename = Path.basename(clonedFile.path, ".ls")
    json = @isJson or ".json" is Path.extname(filename)

    newFilename = if json then Path.basename(filename, ".json") + ".json" else filename + ".js"
    clonedFile.path = Path.join(dirname, newFilename)
    json
