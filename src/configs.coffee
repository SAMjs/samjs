# out: ../lib/configs.js

module.exports = (samjs) ->
  fs = samjs.Promise.promisifyAll(require("fs"))
  class Config
    constructor: (options) ->
      if not options or not options.name
        throw new Error("config needs 'name' property")
      if options.test
        @_test = options.test
        delete options.test
      else
        @_test= (data) -> samjs.Promise.resolve(data)
      samjs.helper.merge(dest:@,src:options,overwrite:true)
      @class = "Config"
      @isRequired ?= false

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

    _set: (newContent) =>
      return @_test(newContent)
        .then =>
          return fs.readFileAsync samjs.options.config
          .catch -> return "{}"
          .then JSON.parse
          .catch -> return {}
          .then (data) =>
            data[@name] = newContent
            @data = newContent
            return fs.writeFileAsync samjs.options.config, JSON.stringify(data)
        .then =>
          samjs.emit "#{@name}.updated", newContent
          return newContent
  samjs.configs = (configs...) ->
    samjs.helper.inOrder("configs")
    configs = samjs.helper.parseSplats(configs)
    samjs.debug.configs("emitting 'beforeConfigs'")
    samjs.emit "beforeConfigs", configs
    samjs.debug.configs("processing")
    mutators = []
    defaults = []
    gets = []
    sets = []
    tests = []
    for plugin in samjs._plugins
      if plugin.configs?
        plugin.debug("got configs")
        if plugin.configs.defaults?
          if samjs.util.isFunction plugin.configs.defaults
            defaults = defaults.concat plugin.configs.defaults(samjs)
          else
            defaults = defaults.concat plugin.configs.defaults
        mutators.push plugin.configs.mutator if plugin.configs.mutator?
        tests.push plugin.configs.test if plugin.configs.test?
        gets.push plugin.configs.get if plugin.configs.get?
        sets.push plugin.configs.set if plugin.configs.set?
    reader = fs.readFileAsync(samjs.options.config)
      .then JSON.parse
      .catch samjs.debug.configs
    createConfig = (options) ->
      for mutator in mutators
        options = mutator(options)
      config = new Config(options)
      config.load(reader).catch ->
      config.set = ((data, client) ->
        return samjs.Promise.reject(new Error("no permission")) unless @write
        for setter in sets
          try
            data = setter.bind(@)(data,client)
          catch e
            return samjs.Promise.reject(e)
        return @._set(data)
        ).bind(config)
      config.test = ((data, client) ->
        return samjs.Promise.reject(new Error("no permission")) unless @write
        for tester in tests
          try
            data = tester.bind(@)(data,client)
          catch e
            return samjs.Promise.reject(e)
        return @._test(data)
        ).bind(config)
      config.get = ((client) ->
        return samjs.Promise.reject(new Error("no permission")) unless @read
        for getter in gets
          try
            getter.bind(@)(client)
          catch e
            return samjs.Promise.reject(e)
        return @._get()
        ).bind(config)
      samjs.debug.configs "setting configs.#{config.name}"
      samjs.configs[config.name] = config
    for config in configs
      createConfig(config)
    for def in defaults
      createConfig(def) unless samjs.configs[def.name]?
    samjs.debug.configs("emitting 'configs'")
    samjs.emit "configs", configs
    samjs.debug.configs("finished")
    samjs.expose.models()
    return samjs
