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
      console.log "onDidSave"
      @validate()

    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      editor.getBuffer().onDidSave ->
        wrap() if atom.config.get 'redpen.validateOnSave'
    # @validateOnSaveObserveSubscription =
    #   atom.config.observe 'redpen.validateOnSave', (flag) =>
    #     console.log flag
    #     if flag
    #       @onSaveSubscriptions = atom.workspace.observeTextEditors (editor) ->
    #         editor.onDidSave wrap
    #     else
    #       if @onSaveSubscriptions?
    #         console.log "dispose"
    #         @onSaveSubscriptions.dispose()
    #         @onSaveSubscriptions = null


  deactivate: ->
    @subscriptions.dispose()
    @validator?.destroy()
    @validator = null

  validate: ->
    handler = (accepts) =>
      if accepts
        @validator.validate()

    @validator.needsValidateAsync handler

  createValidator: ->
    unless @validator?
      Validator = require './redpenValidator'
      @validator = new Validator()
