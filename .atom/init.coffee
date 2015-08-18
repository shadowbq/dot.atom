# Your init script
#
# Atom will evaluate this file each time a new window is opened. It is run
# after packages are loaded/activated and after the previous editor state
# has been restored.
#
# An example hack to log to the console when each text editor is saved.
#
# atom.workspace.observeTextEditors (editor) ->
#   editor.onDidSave ->
#     console.log "Saved! #{editor.getPath()}"
atom.commands.add 'atom-workspace', 'custom-commands:dismiss-notifications', (e) ->
  dismissedCounter = 0
  atom.notifications.getNotifications().forEach (notification) ->
    unless notification.dismissed
      notification.dismiss()
      dismissedCounter++
  if dismissedCounter is 0
    atom.commands.dispatch e.currentTarget, 'core:cancel'

#example init.coffee
path = require 'path'
