# out: ../lib/plugins.js
module.exports = (samjs) ->
  validateHelper = (plugin, prop, type) ->
    path = prop.split(".")
    obj = plugin
    for p in path
      obj = obj[p]
      return unless obj?
    unless samjs.util["is"+type] obj
      e = "plugin.#{prop} must be a #{type}"
      if plugin.name
        e += " - plugin: #{plugin.name}"
      throw new Error e
  validate = (plugin) ->
    unless samjs.util.isObject(plugin)
      throw new Error "plugin needs to be an object or function"
    unless plugin.debug
      if plugin.name
        plugin.debug = samjs.debug(plugin.name)
      else
        plugin.debug = () ->
    validateHelper(plugin, "debug", "Function")
    validateHelper(plugin, "name", "String")
    validateHelper(plugin, "obj", "Object")
    validateHelper(plugin, "options", "Object")
    validateHelper(plugin, "configs", "Object")
    validateHelper(plugin, "options.defaults", "Object")
    validateHelper(plugin, "configs.mutator", "Function")
    validateHelper(plugin, "configs.gets", "Function")
    validateHelper(plugin, "configs.sets", "Function")
    validateHelper(plugin, "configs.tests", "Function")
    validateHelper(plugin, "models", "Object")
    validateHelper(plugin, "models.defaults", "Object")
    if plugin.models?.defaults?
      name = ""
      if plugin?.name?
        name = " - plugin: #{plugin.name}"
      for model in plugin.models.defaults
        unless model.name?
          throw new Error "default models need a 'name'"+name
        unless samjs.util.isString model.name
          throw new Error "default models name needs to be a string"+name
        unless model.isExisting?
          throw new Error "default model #{model.name} need a 'isExisting' function"+name
        unless samjs.util.isFunction model.isExisting
          throw new Error "default models 'isExisting' needs to be a function"+name
    validateHelper(plugin, "startup", "Function")
    validateHelper(plugin, "shutdown", "Function")


  samjs.plugins = (plugins...) ->
    samjs.helper.inOrder("plugins")
    plugins = samjs.helper.parseSplats(plugins)
    samjs._plugins = []
    samjs.debug.plugins("emitting 'beforePlugins'")
    samjs.emit "beforePlugins", plugins
    samjs.debug.plugins("processing")
    for plugin in plugins
      if samjs.util.isFunction plugin
        plugin = plugin(samjs)
        unless samjs.util.isObject plugin
          throw new Error "generator function for plugin should return an object"
      validate plugin
      if plugin.name? and plugin.obj?
        plugin.debug("exposing #{plugin.name}")
        samjs[plugin.name] = plugin.obj
      if plugin.models?.defaults?
        for model in plugin.models.defaults
          unless model.isExisting?
            throw new Error("default models need 'isExisting' function'")
      samjs._plugins.push plugin
    samjs.debug.options("emitting 'plugins'")
    samjs.emit "plugins", samjs._plugins
    samjs.debug.plugins("finished")
    samjs.expose.options()
    return samjs
