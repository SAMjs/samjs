# out: ../lib/configs.js

module.exports = (samjs) ->
  fs = samjs.Promise.promisifyAll(require("fs"))
  asyncHooks = ["afterGet","afterSet","afterTest","after_Get"
    "beforeGet","beforeSet","beforeTest","before_Set"]
  syncHooks = ["afterCreate","beforeCreate"]

  class Config
    constructor: (options) ->
      if not options or not options.name
        throw new Error("config needs 'name' property")
      @name = options.name
      delete options.name
      @class = "Config"
      samjs.helper.initiateHooks(@,asyncHooks,syncHooks)
      for plugin in samjs._plugins
        if plugin.hooks?.configs?
          for hookname, hooks of plugin.hooks.configs
            @addHook(hookname,hooks)
      options = @_hooks.beforeCreate options
      if options.test
        @_test = options.test
        delete options.test
      else
        if options.isRequired
          @_test = (data) -> new samjs.Promise (resolve, reject) ->
            if data?
              resolve(data)
            else
              reject(data)
        else
          @_test = (data) -> samjs.Promise.resolve(data)
      for hookname,hooks of options.hooks
        @addHook(hookname,hooks)
      delete options.hooks
      samjs.helper.merge(dest:@,src:options,overwrite:true)

      @isRequired ?= false
      @_hooks.afterCreate @
      return @
    load: (reader) =>
      @loaded = reader
        .then (data) =>
          if data?[@name]?
            return @data = data[@name]
          else
            throw new Error "config #{@name} not set"
    _getBare: () =>
      if @data?
        return samjs.Promise.resolve @data
      else if @loaded?.isPending()
        return @loaded
      else
        return samjs.Promise.reject new Error "config #{@name} not set"
    _get: () =>
      return @_getBare()
        .catch () ->
          return null
        .then @_hooks.after_Get
    get: (client) =>
      return samjs.Promise.reject(new Error("no permission")) unless @read
      return @_hooks.beforeGet(client: client)
        .then @_get
        .then @_hooks.afterGet

    _set: (newData) =>
      return @_test(newData, @data)
        .then => @_hooks.before_Set(data:newData, oldData: @data)
        .then ({data}) =>
          newData = data
          return fs.readFileAsync samjs.options.config
            .catch -> return "{}"
            .then JSON.parse
            .catch -> return {}
            .then (data) =>
              data[@name] = newData
              @data = newData
              return fs.writeFileAsync samjs.options.config, JSON.stringify(data)
        .then @_hooks.after_Set

    set: (data, client) =>
      return samjs.Promise.reject(new Error("no permission")) unless @write
      return @_hooks.beforeSet(data: data, client: client)
        .then ({data}) => @_set(data)
        .then @_hooks.afterSet

    test: (data, client) ->
      return samjs.Promise.reject(new Error("no permission")) unless @write
      return @_hooks.beforeTest(data: data, client: client)
        .then ({data}) => @_test(data, @data)
        .then @_hooks.afterTest

  samjs.configs = (configs...) ->
    samjs.helper.inOrder("configs")
    configs = samjs.helper.parseSplats(configs)
    samjs.lifecycle.beforeConfigs configs
    samjs.debug.configs("processing")
    defaults = []
    for plugin in samjs._plugins
      if plugin.configs?
        plugin.debug("got configs")
        if samjs.util.isFunction plugin.configs
          defaults = defaults.concat plugin.configs(samjs)
        else
          defaults = defaults.concat plugin.configs
    reader = fs.readFileAsync(samjs.options.config)
      .then JSON.parse
      .catch samjs.debug.configs
    createConfig = (options) ->
      config = new Config(options)
      config.load(reader).catch -> null
      samjs.debug.configs "setting configs.#{config.name}"
      samjs.configs[config.name] = config
    for config in configs
      createConfig(config)
    for def in defaults
      createConfig(def) unless samjs.configs[def.name]?
    samjs.lifecycle.configs configs
    samjs.debug.configs("finished")
    samjs.expose.models()
    return samjs
