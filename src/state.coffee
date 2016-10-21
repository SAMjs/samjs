# out: ../lib/state.js

module.exports = (samjs) ->
  # out: ../lib/hooks.js
  stateNames = ["configure","configured","install","installed","started"]
  asyncStateNames = ["beforeExposing"]
  lifecycleNames = ["reset","beforeConfigure","beforeInstall"].concat stateNames
  for prop in samjs.order
    lifecycleNames.push prop
    lifecycleNames.push "before"+prop.charAt(0).toUpperCase()+prop.slice(1)


  lifecycleNames = lifecycleNames.concat(asyncStateNames)

  samjs.lifecycle = new class Lifecycle
    constructor: ->
      lifecycleNames.forEach (name) =>
        @[name] = (obj) ->
          samjs.debug.lifecycle name
          samjs.emit name, obj
          return samjs._hooks[name](obj)


  samjs.state = new class State
    constructor: ->
      @init()
    init: ->
      samjs.helper.initiateHooks(samjs, asyncStateNames, lifecycleNames)
      for prop in stateNames
        name = "once"+prop.charAt(0).toUpperCase()+prop.slice(1)
        @[name] = new samjs.Promise (resolve) ->
          samjs.once prop, resolve
      @onceConfigureOrInstall = new samjs.Promise (resolve) ->
        resolveAndCleanup = ->
          resolve()
          samjs.removeListener "configure", resolveAndCleanup
          samjs.removeListener "install", resolveAndCleanup
        samjs.once "configure", resolveAndCleanup
        samjs.once "install", resolveAndCleanup
      emitAndCleanup = ->
        samjs.emit "beforeConfigureOrInstall"
        samjs.removeListener "beforeConfigure", emitAndCleanup
        samjs.removeListener "beforeInstall", emitAndCleanup
      samjs.once "beforeConfigure", emitAndCleanup
      samjs.once "beforeInstall", emitAndCleanup

    reset: =>
      @init()

    ifConfigured: (exclude) ->
      samjs.configs.isConfigured._get()
      .then (isConfigured) ->
        return if isConfigured
        required = []
        for k,v of samjs.configs
          if v? and v.isRequired and v._test? and v.name != exclude
            required.push v._getBare().then(v._test)
        return samjs.Promise.all(required)
          .then -> samjs.configs.isConfigured._set(true)
          .catch (e) -> throw new Error "not configured"
    ifInstalled: ->
      samjs.configs.isInstalled._get()
      .then (isInstalled) ->
        return if isInstalled
        required = []
        for k,v of samjs.models
          if v?.isRequired? and v.isRequired and v.test?
            required.push v.test.bind(v)()
        return samjs.Promise.all(required)
          .then -> samjs.configs.isInstalled._set(true)
          .catch (e) -> throw new Error "not installed"
    checkInstalled: =>
      @ifInstalled()
      .then  -> samjs.lifecycle.installed()
      .catch -> return true
