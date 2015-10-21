childProcess = require 'child_process'
exec = childProcess.exec

plugin = module.exports =
  activate: () ->
    atom.commands.add 'atom-workspace', 'atom-zeal:context-menu', => @contextMenu()
    atom.commands.add 'atom-workspace', 'atom-zeal:shortcut', => @shortcut()

  shortcut: () ->
    editor    = atom.workspace.getActiveTextEditor()
    selection = editor.getSelectedText()

    return plugin.search(selection) if selection

    editor.selectWordsContainingCursors()
    selection = editor.getSelectedText()

    plugin.search(selection)

  contextMenu: () ->
    editor    = atom.workspace.getActiveTextEditor()
    editor.selectWordsContainingCursors()
    selection = editor.getSelectedText()
    plugin.search(selection)

  search: (string) ->
    exec('zeal --query "' + string + '"')
