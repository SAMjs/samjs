# out: ../lib/configs.js

module.exports = (samjs) ->
  fs = samjs.Promise.promisifyAll(require("fs"))
  asyncHooks = ["afterGet","afterSet","afterTest","after_Get","after_Set"
    "beforeGet","beforeSet","beforeTest","before_Set"]
  syncHooks = ["afterCreate","beforeCreate"]

  listener = (socket) ->
    # tester
    samjs.debug.configs "listening on "+ @name + ".test"
    socket.on @name + ".test", (request) =>
      if request?.content? and request.token?
        @test.bind(@)(request.content, socket)
        .then ({data}) -> success:true , content:data
        .catch (err) -> success:false, content:err?.message
        .then (response) =>
          socket.emit @name + ".test." + request.token, response
    # getter
    samjs.debug.configs "listening on "+ @name + ".get"
    socket.on @name + ".get", (request) =>
      if request?.token?
        @get.bind(@)(socket)
        .then ({data}) -> success:true , content:data
        .catch (err)     -> success:false, content:err?.message
        .then (response) =>
          socket.emit @name + ".get." + request.token, response
    # setter
    samjs.debug.configs "listening on "+ @name + ".set"
    socket.on @name + ".set", (request) =>
      if request?.content? and request.token?
        @set.bind(@)(request.content, socket)
        .then ({data}) ->
          socket.broadcast.emit "updated", @name
          success:true , content:data
        .catch (err)     -> success:false, content:err?.message
        .then (response) =>
          socket.emit @name + ".set." + request.token, response

  class Config
    constructor: (options) ->
      if not options or not options.name
        throw new Error("config needs 'name' property")
      @name = options.name
      @class = "Config"
      samjs.helper.initiateHooks(@,asyncHooks,syncHooks)
      samjs.configs._hooks.beforeProcess(@)
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
      @access ?= {}
      @isRequired ?= false
      @_hooks.afterCreate @
      samjs.configs._hooks.afterProcess(@)
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
    get: (socket) =>
      return samjs.Promise.reject(new Error("no permission")) unless @access.read
      return @_hooks.beforeGet(socket: socket)
        .then @_get
        .then (data) =>
          @_hooks.afterGet(data:data, socket: socket)

    _set: (newData) =>
      oldData = @data
      return @_test(newData, oldData)
        .then => @_hooks.before_Set(data:newData, oldData: oldData)
        .then ({data}) =>
          newData = data
          return fs.readFileAsync samjs.options.config
            .catch -> return "{}"
            .then JSON.parse
            .catch -> return {}
            .then (data) =>
              data[@name] = newData
              @data = newData
              fs.writeFileAsync samjs.options.config, JSON.stringify(data)
        .then => @_hooks.after_Set(data:newData, oldData: oldData)

    set: (data, socket) =>
      return samjs.Promise.reject(new Error("no permission")) unless @access.write
      return @_hooks.beforeSet(data: data, socket: socket)
        .then ({data}) => @_set(data)
        .then ({data,oldData}) =>
          @_hooks.afterSet({data:data,oldData:oldData,socket:socket})

    test: (data, socket) ->
      return samjs.Promise.reject(new Error("no permission")) unless @access.write
      return @_hooks.beforeTest(data: data, socket: socket)
        .then ({data}) => @_test(data, @data)
        .then (data) => @_hooks.afterTest(data: data, socket:socket)

  samjs.configs = (configs...) ->
    samjs.helper.inOrder("configs")
    samjs.helper.initiateHooks(samjs.configs,[],["afterProcess","beforeProcess"])
    configs = samjs.helper.parseSplats(configs)
    samjs.lifecycle.beforeConfigs configs
    samjs.debug.configs("processing")
    defaults = [
      {name:"isInstalled"}
      {name:"isConfigured"}
    ]
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
    for name, config of samjs.configs
      if config?.name?
        samjs.interfaces.add "config", listener.bind(config)
    samjs.lifecycle.configs configs
    samjs.debug.configs("finished")
    samjs.expose.models()
    return samjs
