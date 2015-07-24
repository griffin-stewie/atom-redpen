path = require 'path'
parser = require './redpenResultParser'
{MessagePanelView, LineMessageView, PlainMessageView} = require 'atom-message-panel'

detectedInputFormat = () ->
  editor = atom.workspace.getActiveTextEditor()
  switch editor.getGrammar().scopeName
    when 'source.gfm' then "markdown"
    when 'text.html.textile' then "wiki"
    when 'source.asciidoc' then "asciidoc"
    else "plain"


module.exports =
  class Validator

    constructor: (args) ->
      @messagePanel = new MessagePanelView title: '<span class="icon-bug"></span> RedPen report', rawTitle: true unless @messagePanel?
      atom.workspace.onDidChangeActivePaneItem =>
        @messagePanel?.close()

    destroy: ->
      @messagePanel?.remove()
      @messagePanel = null

    needsValidateAsync: (callback) ->
      editor = atom.workspace.getActiveTextEditor()
      grammars = [
          'source.gfm'
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
          requiresVersion = "1.3"
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
      unless pathForConfigurationXMLFile? and pathForConfigurationXMLFile.trim() isnt ''
        packageRootPath = atom.packages.resolvePackagePath("redpen")
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
