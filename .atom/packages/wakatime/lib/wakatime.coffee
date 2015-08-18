###
WakaTime
Description: Analytics for programmers.
Maintainer:  WakaTime <support@wakatime.com>
License:     BSD, see LICENSE for more details.
Website:     https://wakatime.com/
###

AdmZip = require 'adm-zip'
fs = require 'fs'
os = require 'os'
path = require 'path'
process = require 'child_process'
request = require 'request'
rimraf = require 'rimraf'

latestCLIVersion = '4.1.0'

module.exports =

  activate: (state) ->
    window.VERSION = atom.packages.getLoadedPackage('wakatime').metadata.version

    if not isCLIInstalled()
      installCLI(->
        console.log 'Finished installing wakatime cli.'
      )
    else
      isCLILatest((latest) ->
        if not latest
          installCLI(->
            console.log 'Finished installing wakatime cli.'
          )
      )
    isPythonInstalled((installed) ->
      if not installed
        installPython()
    )
    setupConfig()
    setupEventHandlers()
    console.log 'WakaTime v'+VERSION+' loaded.'

lastHeartbeat = 0
lastFile = ''

enoughTimePassed = (time) ->
  return lastHeartbeat + 120000 < time

setupConfig = () ->
  unless atom.config.get("wakatime.apikey")?
    defaults =
      apikey: ""
      ignore: ["^/var/", "^/tmp/", "^/private/", "COMMIT_EDITMSG$", "PULLREQ_EDITMSG$", "MERGE_MSG$"]
    atom.config.set("wakatime", defaults)

setupEventHandlers = () ->
  atom.workspace.observeTextEditors (editor) =>
    try
      buffer = editor.getBuffer()
      buffer.onDidSave (e) =>
        file = buffer.file
        if file? and file
          lineno = null
          if editor.cursors.length > 0
            lineno = editor.cursors[0].getCurrentLineBufferRange().end.row + 1
          sendHeartbeat(file, lineno, true)
      buffer.onDidChange (e) =>
        file = buffer.file
        if file? and file
          lineno = null
          if editor.cursors.length > 0
            lineno = editor.cursors[0].getCurrentLineBufferRange().end.row + 1
          sendHeartbeat(file, lineno)
      editor.onDidChangeCursorPosition (e) =>
        file = buffer.file
        if file? and file
          lineno = null
          if editor.cursors.length > 0
            lineno = editor.cursors[0].getCurrentLineBufferRange().end.row + 1
          sendHeartbeat(file, lineno)

isPythonInstalled = (callback) ->
  pythonLocation((result) ->
    callback(result?)
  )

pythonLocation = (callback, locations) ->
  if global.cachedPythonLocation?
    callback(global.cachedPythonLocation)
  else
    if not locations?
      locations = [
        "pythonw",
        "python",
        "/usr/local/bin/python",
        "/usr/bin/python",
        "\\python37\\pythonw",
        "\\Python37\\pythonw",
        "\\python36\\pythonw",
        "\\Python36\\pythonw",
        "\\python35\\pythonw",
        "\\Python35\\pythonw",
        "\\python34\\pythonw",
        "\\Python34\\pythonw",
        "\\python33\\pythonw",
        "\\Python33\\pythonw",
        "\\python32\\pythonw",
        "\\Python32\\pythonw",
        "\\python31\\pythonw",
        "\\Python31\\pythonw",
        "\\python30\\pythonw",
        "\\Python30\\pythonw",
        "\\python27\\pythonw",
        "\\Python27\\pythonw",
        "\\python26\\pythonw",
        "\\Python26\\pythonw",
        "\\python37\\python",
        "\\Python37\\python",
        "\\python36\\python",
        "\\Python36\\python",
        "\\python35\\python",
        "\\Python35\\python",
        "\\python34\\python",
        "\\Python34\\python",
        "\\python33\\python",
        "\\Python33\\python",
        "\\python32\\python",
        "\\Python32\\python",
        "\\python31\\python",
        "\\Python31\\python",
        "\\python30\\python",
        "\\Python30\\python",
        "\\python27\\python",
        "\\Python27\\python",
        "\\python26\\python",
        "\\Python26\\python",
      ]
    args = ['--version']
    if locations.length is 0
      callback(null)
      return
    location = locations[0]
    process.execFile(location, args, (error, stdout, stderr) ->
      if not error?
        global.cachedPythonLocation = location
        callback(location)
      else
        locations.splice(0, 1)
        pythonLocation(callback, locations)
    )

installPython = () ->
  if os.type() is 'Windows_NT'
    url = 'https://www.python.org/ftp/python/3.4.2/python-3.4.2.msi';
    if os.arch().indexOf('x64') > -1
      url = "https://www.python.org/ftp/python/3.4.2/python-3.4.2.amd64.msi";
    console.log 'Downloading python...'
    msiFile = __dirname + path.sep + 'python.msi'
    downloadFile(url, msiFile, ->
      console.log 'Installing python...'
      args = ['/i', msiFile, '/norestart', '/qb!']
      process.execFile('msiexec', args, (error, stdout, stderr) ->
        if error?
          console.warn error
          window.alert('Error encountered while installing Python.')
        else
          fs.unlink(msiFile)
          console.log 'Finished installing python.'
      )
    )
  else
    window.alert('WakaTime depends on Python. Install it from https://python.org/downloads then restart Atom.')

isCLIInstalled = () ->
  return fs.existsSync(cliLocation())

isCLILatest = (callback) ->
  pythonLocation((python) ->
    if python?
      args = [cliLocation(), '--version']
      process.execFile(python, args, (error, stdout, stderr) ->
        if not error?
          if stderr.trim() == latestCLIVersion
            callback(true)
          else
            callback(false)
        else
          callback(false)
      )
  )

cliLocation = () ->
  dir = __dirname + path.sep + 'wakatime-master' + path.sep + 'wakatime' + path.sep + 'cli.py'
  return dir

installCLI = (callback) ->
  console.log 'Downloading wakatime cli...'
  url = 'https://github.com/wakatime/wakatime/archive/master.zip'
  zipFile = __dirname + path.sep + 'wakatime-master.zip'
  downloadFile(url, zipFile, ->
    extractCLI(zipFile, callback)
  )

extractCLI = (zipFile, callback) ->
  console.log 'Extracting wakatime-master.zip file...'
  if fs.existsSync(__dirname + path.sep + 'wakatime-master')
    try
      rimraf(__dirname + path.sep + 'wakatime-master', ->
        unzip(zipFile, __dirname, callback)
      )
    catch e
      console.warn e
      unzip(zipFile, __dirname, callback)
  else
    unzip(zipFile, __dirname, callback)

downloadFile = (url, outputFile, callback) ->
  r = request(url)
  out = fs.createWriteStream(outputFile)
  r.pipe(out)
  r.on('end', ->
    out.on('finish', ->
      if callback?
        callback()
    )
  )

unzip = (file, outputDir, callback) ->
  if fs.existsSync(file)
    zip = new AdmZip(file)
    try
      zip.extractAllTo(outputDir, true)
    catch e
      console.warn e
    finally
      fs.unlink(file)
      if callback?
        callback()

sendHeartbeat = (file, lineno, isWrite) ->
  time = Date.now()
  if isWrite or enoughTimePassed(time) or lastFile isnt file.path
    if not file.path? or file.path is undefined or fileIsIgnored(file.path)
      return
    pythonLocation((python) ->
      if python?
        apikey = atom.config.get('wakatime.apikey')
        unless apikey
          return

        args = [cliLocation(), '--file', file.path, '--key', apikey, '--plugin', 'atom-wakatime/' + VERSION]
        if isWrite
          args.push('--write')
        if lineno?
          args.push('--lineno')
          args.push(lineno)
        process.execFile(python, args, (error, stdout, stderr) ->
          if error?
            console.warn error
          # else
          #     console.log(args)
        )
        lastHeartbeat = time
        lastFile = file.path
    )

fileIsIgnored = (file) ->
  if endsWith(file, 'COMMIT_EDITMSG') or endsWith(file, 'PULLREQ_EDITMSG') or endsWith(file, 'MERGE_MSG') or endsWith(file, 'TAG_EDITMSG')
    return true
  patterns = atom.config.get("wakatime.ignore")
  ignore = false
  for pattern in patterns
    re = new RegExp(pattern, "gi")
    if re.test(file)
      ignore = true
      break
  return ignore

endsWith = (str, suffix) ->
  if str? and suffix?
    return str.indexOf(suffix, str.length - suffix.length) != -1
  return false
