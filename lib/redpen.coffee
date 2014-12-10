RedpenView = require './redpen-view'
{CompositeDisposable} = require 'atom'

msgPanel = require 'atom-message-panel';

module.exports = Redpen =
  redpenView: null
  modalPanel: null
  subscriptions: null

  configDefaults:
    pathForRedPen: "/usr/local/redpen/bin/redpen"
    grammars: [
      'source.markdown'
      'text.plain'
      'text.plain.null-grammar'
    ]

  activate: (state) ->
    @redpenView = new RedpenView(state.redpenViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @redpenView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'redpen:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @redpenView.destroy()

  serialize: ->
    redpenViewState: @redpenView.serialize()

  toggle: ->
    console.log 'Redpen was toggled!'

    editor = atom.workspace.getActivePaneItem()
    pathForSource = editor.getPath()
    previousActivePane = atom.workspace.getActivePane()

    inputFormat = "markdown"
    resultFormat = "xml"

    tempOutput = "/tmp/redpen_result.xml"

    @exec = require('child_process').exec

    redpen = atom.config.get "redpen.pathForRedPen"

    console.log redpen
    console.log pathForSource

    command = "export JAVA_HOME='/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk/Contents/Home'; #{redpen} -c /Users/Stewie/github/redpen/redpen-conf-ja.xml -r xml -f markdown #{pathForSource}"

    if atom.workspaceView.find('.am-panel').length != 1
      msgPanel.init('<span class="icon-bug"></span> RedPen report');
    else
      msgPanel.clear();


    # ここでコマンド実行
    @exec command, (error, stdout, stderr) ->
      if error?
        console.log "Script Somthing wrong"
        console.log stderr

        msgPanel.append.lineMessage(0, 0, error.message, stdout, 'text-error');

      else
        console.log "Script executed"
        console.log stdout
