path = require 'path'
parser = require './redpenResultParser'
{MessagePanelView, LineMessageView, PlainMessageView} = require 'atom-message-panel'

detectedInputFormat = () ->
  editor = atom.workspace.getActiveEditor()
  switch editor.getGrammar().scopeName
    when 'source.gfm' then "markdown"
    when 'text.html.textile' then "wiki"
    else "plain"


module.exports =
  class Validator

    constructor: (args) ->
      @messagePanel = new MessagePanelView title: '<span class="icon-bug"></span> RedPen report', rawTitle: true, closeMethod: "destroy"  unless @messagePanel?

    destroy: ->
        @messagePanel?.remove()
        @messagePanel = null

    validate: ->
      file = atom.workspace.getActivePaneItem()
      pathForSource = file.getPath()
      editor = atom.workspace.getActiveEditor()
      grammars = [
          'source.gfm'
          'text.html.textile'
          'text.plain'
          'text.plain.null-grammar'
      ]
      return unless editor.getGrammar().scopeName in grammars

      # console.log atom.workspaceView.find('.am-panel').length

      if atom.workspaceView.find('.am-panel').length is 0
        @messagePanel.attach();

      @messagePanel.clear();

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

      command = "export JAVA_HOME='#{JAVA_HOME}'; #{redpen} -c #{pathForConfigurationXMLFile} -r xml -f #{inputFormat} #{pathForSource}"
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

        if result["validation-result"].error instanceof Array
          # console.log "some results"
          for val in result["validation-result"].error
            @messagePanel.add new LineMessageView
              line: val.lineNum,
              character: 0,
              message: val.message,
              preview: val.sentence,
              className: 'text-error'

        else if result["validation-result"].error instanceof Object
          # console.log "1 result"
          val = result["validation-result"].error
          @messagePanel.add new LineMessageView
            line: val.lineNum,
            character: 0,
            message: val.message,
            preview: val.sentence,
            className: 'text-error'

        else
          console.log "success"
          @messagePanel.add new PlainMessageView message: "Success", className: 'text-success'
