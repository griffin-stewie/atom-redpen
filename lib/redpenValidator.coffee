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

    needsValidate: ->
      editor = atom.workspace.getActiveTextEditor()
      grammars = [
          'source.gfm'
          'source.asciidoc'
          'text.html.textile'
          'text.plain'
          'text.plain.null-grammar'
      ]

      if editor.getGrammar().scopeName in grammars
        return true
      else
        return false

    versionCheck: (callback) ->
      unless @needsValidate()
        callback(false)
      else
        @exec = require('child_process').exec
        redpen = atom.config.get "redpen.pathForRedPen"
        JAVA_HOME = atom.config.get "redpen.JAVA_HOME"
        unless JAVA_HOME? and JAVA_HOME.trim() isnt ''
          errorMessage = 'JAVA_HOME is missing. See preferences.'
          @messagePanel.attach()
          @messagePanel.clear()
          @messagePanel.add new PlainMessageView message: errorMessage, className: 'text-error'
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

          requireMajorVersion = "1"

          if stdout.length > 0 && stdout[0] isnt requireMajorVersion
            console.log "v#{requireMajorVersion} 以下"
            @messagePanel.attach()
            @messagePanel.clear()
            errorMessage = "redpen package requires RedPenCLI v#{requireMajorVersion} or higher update your RedPenCLI"
            @messagePanel.add new PlainMessageView message: errorMessage, className: 'text-error'
            callback(false)
          else
            console.log "v#{requireMajorVersion} 以上"
            callback(true)

    validate: ->
      return unless @needsValidate()

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
