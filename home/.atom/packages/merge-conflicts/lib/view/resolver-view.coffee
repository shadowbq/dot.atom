{CompositeDisposable} = require 'atom'
{View} = require 'space-pen'

{GitBridge} = require '../git-bridge'

{handleErr} = require './error-view'


class ResolverView extends View

  @content: (editor, state, pkg) ->
    @div class: 'overlay from-top resolver', =>
      @div class: 'block text-highlight', "We're done here"
      @div class: 'block', =>
        @div class: 'block text-info', =>
          @text "You've dealt with all of the conflicts in this file."
        @div class: 'block text-info', =>
          @span outlet: 'actionText', 'Save and stage'
          @text ' this file for commit?'
      @div class: 'pull-left', =>
        @button class: 'btn btn-primary', click: 'dismiss', 'Maybe Later'
      @div class: 'pull-right', =>
        @button class: 'btn btn-primary', click: 'resolve', 'Stage'

  initialize: (@editor, @state, @pkg) ->
    @subs = new CompositeDisposable()

    @refresh()
    @subs.add @editor.onDidSave => @refresh()

    @subs.add atom.commands.add @element, 'merge-conflicts:quit', => @dismiss()

  detached: -> @subs.dispose()

  getModel: -> null

  relativePath: ->
    @state.repo.relativize @editor.getURI()

  refresh: ->
    GitBridge.isStaged @state.repo, @relativePath(), (err, staged) =>
      return if handleErr(err)

      modified = @editor.isModified()

      needsSaved = modified
      needsStaged = modified or not staged

      unless needsSaved or needsStaged
        @hide 'fast', -> @remove()
        @pkg.didStageFile file: @editor.getURI()
        return

      if needsSaved
        @actionText.text 'Save and stage'
      else if needsStaged
        @actionText.text 'Stage'

  resolve: ->
    @editor.save()
    GitBridge.add @state.repo, @relativePath(), (err) =>
      return if handleErr(err)

      @refresh()

  dismiss: ->
    @hide 'fast', => @remove()

module.exports =
  ResolverView: ResolverView
