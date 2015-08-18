###
 * Open Terminal Here - Atom package
 * https://github.com/blueimp/atom-open-terminal-here
 *
 * Copyright 2015, Sebastian Tschan
 * https://blueimp.net
 *
 * Licensed under the MIT license:
 * http://opensource.org/licenses/MIT
###

switch require('os').platform()

  when 'darwin'
    defaultCommand = 'open -a Terminal.app "$PWD"'

  when 'win32'
    defaultCommand = 'start /D "%cd%" cmd'

  else
    defaultCommand = 'x-terminal-emulator'

module.exports =

  config: {
    command:
      type: 'string'
      default: defaultCommand
  },

  activate: ->
    atom.commands.add '.tree-view .selected, atom-text-editor, atom-workspace',
      'open-terminal-here:open': (event) ->

        event.stopImmediatePropagation()

        filepath = @getPath?() || @getModel?().getPath?() ||
          atom.workspace.getActivePaneItem()?.buffer?.file?.path ||
          atom.project.getDirectories()[0]?.path

        return if not filepath

        if require('fs').lstatSync(filepath).isFile()
          dirpath = require('path').dirname(filepath)
        else
          dirpath = filepath

        command = atom.config.get 'open-terminal-here.command'

        require('child_process').exec command,
          cwd: dirpath
