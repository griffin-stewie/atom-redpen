parser = require './redpenResultParser'
{CompositeDisposable} = require 'atom'

module.exports = Redpen =

  subscriptions: null
  validator: null

  config:
    pathForRedPen:
      title: 'Path for RedPen CLI'
      description: 'Requires v1.0 or higher'
      type: 'string'
      default: "/usr/local/redpen/bin/redpen"
      order: 10
    pathForConfigurationXMLFile:
      title: 'Path for Configuration XML File'
      description: ''
      type: 'string'
      default: ''
      order: 20
    JAVA_HOME:
      title: 'JAVA_HOME Path'
      description: ''
      type: 'string'
      default: ''
      order: 30
    validateOnSave:
      title: 'Validate on save'
      description: 'Run validation each time a file is saved'
      type: 'boolean'
      default: false
      order: 40

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command
    @subscriptions.add atom.commands.add 'atom-workspace', 'redpen:validate': => @validate()

    @validator = @createValidator()

    wrap = () =>
      @validate()

    @validateOnSaveObserveSubscription =
      atom.config.observe 'redpen.validateOnSave', (flag) ->
        if flag
          atom.workspace.eachEditor (editor) ->
            editor.buffer.on 'saved', wrap
        else
          atom.workspace.eachEditor (editor) ->
            editor.buffer.off 'saved', wrap


  deactivate: ->
    @subscriptions.dispose()
    @validator?.destroy()
    @validator = null

  validate: ->
    @validator.versionCheck (result) =>
      if result
        @validator.validate()

  createValidator: ->
    unless @validator?
      Validator = require './redpenValidator'
      @validator = new Validator()
