{CompositeDisposable} = require 'atom'

which = require "which"
fs = require "fs"
tempWrite = require "temp-write"
childProcess = require "child_process"

module.exports = Phpcbf =
  subscriptions: null

  config:
    executablePath:
      type: 'string'
      default: 'phpcbf'
      description: 'Path to the `phpcbf` executable.'
    standard:
      type: 'string'
      enum: ['MySource', 'PEAR', 'PHPCS', 'PSR1', 'PSR2', 'Squiz', 'Zend']
      default: 'PSR2'
      description: 'The PHPCS coding standard to use.'

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'phpcbf.executablePath',
      (executablePath) => @executablePath = executablePath

    @subscriptions.add atom.config.observe 'phpcbf.standard',
      (standard) => @standard = standard

    # @TODO: scope to PHP files.
    @subscriptions.add atom.commands.add 'atom-workspace', 'phpcbf:fix': => @fix()

  deactivate: ->
    @subscriptions.dispose()

  fix: ->
    which @executablePath, (err, phpcbf) =>
      # @TODO: handle error properly: display to the user.
      if err
        throw err
      else if editor = atom.workspace.getActiveTextEditor()
        tempFile = tempWrite.sync(editor.getText())
        args = ["--no-patch", "--standard=#{@standard}", tempFile]
        childProcess.execFile phpcbf, args, (err, stdOut, stdErr) =>
          # Ugh. PHPCBF exits 1 for no apparent reason???
          if err and stdErr.length
            console.log arguments
            throw err
          else
            editor.setText(fs.readFileSync(tempFile, 'utf8'))
