IncludeResourceView = require './html-include-resource-view'
{CompositeDisposable} = require 'atom'
path = require 'path'

module.exports =
  activate: ->
    atom.commands.add 'atom-workspace', "html-include-resource:include", => @include()

  include: ->
    htmlTags = ''
    editor = atom.workspace.getActivePaneItem()
    selection = editor.getLastSelection()
    treeView = atom.packages.getLoadedPackage('tree-view')
    treeView = require(treeView.mainModulePath).treeView
    selectedEntries = treeView.list[0].querySelectorAll('.selected')

    if selectedEntries && editor.getPath
      entryCounter = 0
      newLine = ''

      for entry in selectedEntries
        relativePath = path.relative(''+path.dirname(editor.getPath()),''+path.dirname(entry.getPath()))
        fileName = if relativePath != '' then '/' else ''
        fileName += path.basename(entry.getPath())
        relativePath += fileName

        entryCounter++
        if entryCounter > 1 then newLine = '\n'

        # includes the proper tag depending on the extension
        extension = path.extname(entry.getPath())
        switch extension
          when '.js','.coffee' then htmlTags += newLine+'<script src="'+relativePath+'"></script>'
          when '.css' then htmlTags += newLine+'<link rel="stylesheet" href="'+relativePath+'">'
          when '.svg' then htmlTags += newLine+'<object data="'+relativePath+'" type="image/svg+xml">\n<img src="'+path.dirname(relativePath)+'/'+path.basename(relativePath,".svg")+'fallback.jpg" />\n</object>'
          when '.jpg','.jpeg','.gif','.tiff','.png','.bmp','.rif','webp' then htmlTags += newLine+'<img src="'+relativePath+'" alt="">'
          when '.mp4','.ogg','webm' then htmlTags += newLine+'<video width="320" height="240" controls>\n<source src="'+relativePath+'" type="video/'+extension.replace(".","")+'">\nYour browser does not support the video tag.\n</video>'
          when '.mp3' then htmlTags += newLine+'<audio controls>\n<source src="'+relativePath+'" type="audio/mpeg">\nYour browser does not support the audio element.\n</audio>'
          when '.ogg','.wav' then htmlTags += newLine+'<audio controls>\n<source src="'+relativePath+'" type="audio/'+extension.replace(".","")+'">\nYour browser does not support the audio element.\n</audio>'

      selection.insertText(htmlTags, {'autoIndent':true})
