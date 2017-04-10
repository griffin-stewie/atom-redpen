parser = require './redpenResultParser'
fs = require 'fs'
path = require 'path'
{MessagePanelView, LineMessageView, PlainMessageView} = require 'atom-message-panel'

detectedInputFormat = () ->
  editor = atom.workspace.getActiveTextEditor()
  switch editor.getGrammar().scopeName
    when 'source.gfm' then "markdown"
    when 'text.html.textile' then "wiki"
    when 'source.asciidoc' then "asciidoc"
    when 'text.tex.latex' then "latex"
    else "plain"


module.exports =
  class Validator
    needsValidateAsync: (callback) ->
      editor = atom.workspace.getActiveTextEditor()
      unless editor?
        callback(false)
        return

      grammars = [
          'source.gfm'
          'text.tex.latex'
          'text.html.textile'
          'text.plain'
          'text.plain.null-grammar'
      ]

      versionCheckHandler = (version, errorMessage) ->
        if errorMessage?length > 0
          @messagePanel.attach()
          @messagePanel.clear()
          @messagePanel.add new PlainMessageView message: errorMessage, className: 'text-error'
          callback(false)
          return

        console.log version

        if version?.length > 0
          versionArray = version.split(".")
          console.log versionArray
          if parseInt(versionArray[0], 10) >= 1 and parseInt(versionArray[1], 10) >= 3
            console.log "can handle asciidoc"
            grammars.unshift('source.asciidoc')
          else
            console.log "can't handle asciidoc"

        if editor.getGrammar().scopeName in grammars
          console.log "can't handle asciidoc"
          callback(true)
        else
          console.log "I don't know handle asciidoc"
          callback(false)

      @redpenVersion versionCheckHandler

    constructor: (args) ->
      @messagePanel = new MessagePanelView title: '<span class="icon-bug"></span> RedPen report', rawTitle: true unless @messagePanel?
      atom.workspace.onDidChangeActivePaneItem =>
        @messagePanel?.close()

    destroy: ->
      @messagePanel?.remove()
      @messagePanel = null

    redpenVersion: (callback) ->
      @exec = require('child_process').exec
      redpen = atom.config.get "redpen.pathForRedPen"
      JAVA_HOME = atom.config.get "redpen.JAVA_HOME"
      unless JAVA_HOME? and JAVA_HOME.trim() isnt ''
        errorMessage = 'JAVA_HOME is missing. See preferences.'
        callback(null, errorMessage)
        return

      command = "export JAVA_HOME='#{JAVA_HOME}'; #{redpen} --version"

      # Execute redpen-cli command
      @exec command, (error, stdout, stderr) =>
        console.log "Script executed"
        console.log stdout
        console.log stderr
        console.log error

        if error?
          console.log "Script Somthing wrong"
        else
          console.log "Script executed"

        if stderr.length > 0
          requiresVersion = "1.5"
          errorMessage = "something wrong when redpen version checking. This package requires redpen version #{requiresVersion}"
          callback(null, errorMessage)
        else
          callback(stdout, null)

    validate: ->
      file = atom.workspace.getActivePaneItem()
      pathForSource = file.getPath()

      # console.log atom.workspace.panelForItem(@messagePanel)

      @messagePanel.attach()
      @messagePanel.clear()

      inputFormat = detectedInputFormat()
      resultFormat = "xml"

      tempOutput = "/tmp/redpen_result.xml"

      @exec = require('child_process').exec

      redpen = atom.config.get "redpen.pathForRedPen"
      JAVA_HOME = atom.config.get "redpen.JAVA_HOME"
      unless JAVA_HOME? and JAVA_HOME.trim() isnt ''
        errorMessage = 'JAVA_HOME is missing. See preferences.'
        @messagePanel.add new PlainMessageView message: errorMessage, className: 'text-error'
        return

      pathForConfigurationXMLFile = atom.config.get "redpen.pathForConfigurationXMLFile"
      # console.log pathForConfigurationXMLFile
      pathForConfigurationXMLFile = @resolveConfigLocation(pathForConfigurationXMLFile, pathForSource)

      unless pathForConfigurationXMLFile? and pathForConfigurationXMLFile.trim() isnt ''
        packageRootPath = atom.packages.resolvePackagePath("redpen")
        path = require 'path'
        pathForConfigurationXMLFile = path.join(packageRootPath, "assets", "redpen_conf", "ja", "redpen-conf-ja.xml")

      # console.log redpen
      # console.log pathForSource
      # console.log pathForConfigurationXMLFile

      command = "export JAVA_HOME='#{JAVA_HOME}'; #{redpen} -c #{pathForConfigurationXMLFile} -r json -f #{inputFormat} #{pathForSource}"
      # console.log command

      # Execute redpen-cli command
      @exec command, (error, stdout, stderr) =>
        console.log "Script executed"
        console.log stdout
        console.log stderr
        console.log error

        if error?
          console.log "Script Somthing wrong"
        else
          console.log "Script executed"

        result = parser.parse(stdout)
        console.log result

        if result[0].errors.length > 0
          # console.log "some results"
          for val in result[0].errors
            @messagePanel.add new LineMessageView
              line: val.atomErrorEndPositionRow,
              character: val.atomErrorEndPositionCollum,
              message: val.message,
              preview: val.sentence,
              className: 'text-error'
        else
          console.log "success"
          @messagePanel.add new PlainMessageView message: "Success", className: 'text-success'

    resolveConfigLocation: (configurationXMLPath, targetFilePath) ->
      defaultConfigName = "redpen-conf"
      pathCandidates = []
      locale = atom.config.get "redpen.localeForConfigurationXMLFile"
      console.log "Locale: " + locale

      REDPEN_HOME = process.env["REDPEN_HOME"]

      path = require 'path'

      if configurationXMLPath != null && configurationXMLPath.length > 0
        pathCandidates.push(configurationXMLPath)

      pathToTargetFileDir = path.dirname(targetFilePath)
      pathCandidates.push(path.join(pathToTargetFileDir, defaultConfigName + ".xml"))
      pathCandidates.push(path.join(pathToTargetFileDir, defaultConfigName + "-" + locale + ".xml"))

      for dir in atom.project.getDirectories()
        projPath = dir.getRealPathSync()
        pathCandidates.push(path.join(projPath, defaultConfigName + ".xml"))
        pathCandidates.push(path.join(projPath, defaultConfigName + "-" + locale + ".xml"))

      if REDPEN_HOME?
        pathCandidates.push(path.join(REDPEN_HOME, defaultConfigName + ".xml"))
        pathCandidates.push(path.join(REDPEN_HOME, defaultConfigName + "-" + locale + ".xml"))
        pathCandidates.push(path.join(REDPEN_HOME, "conf", defaultConfigName + ".xml"))
        pathCandidates.push(path.join(REDPEN_HOME, "conf", defaultConfigName + "-" + locale + ".xml"))

      resolved = @resolve(pathCandidates)
      console.log "resolved ConfigXML Path: " + resolved
      return resolved

    resolve: (pathCandidates) ->
      console.log pathCandidates
      for path in pathCandidates
        if fs.existsSync(path) and fs.statSync(path).isFile()
          return path

      return null
