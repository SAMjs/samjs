# out: ../lib/plugins.js
module.exports = (samjs) ->

  validate = (plugin) ->
    unless samjs.util.isObject(plugin)
      throw new Error "plugin needs to be an object"
    unless plugin.debug
      if plugin.name
        plugin.debug = samjs.debug(plugin.name)
      else
        plugin.debug = () ->
    validateHelper = (prop, type) ->
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
    validateHelper("debug", "Function")
    validateHelper("name", "String")
    validateHelper("options", "Object")
    validateHelper("configs", "Array")
    validateHelper("models", "Object")
    validateHelper("models.defaults", "Object")
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
    validateHelper("startup", "Function")
    validateHelper("shutdown", "Function")


  samjs.plugins = (plugins...) ->
    samjs.helper.inOrder("plugins")
    plugins = samjs.helper.parseSplats(plugins)
    samjs._plugins = []
    samjs.lifecycle.beforePlugins plugins
    samjs.debug.plugins("processing")
    for plugin in plugins
      if samjs.util.isFunction plugin
        plugin = plugin(samjs)
      validate plugin
      if plugin.name?
        plugin.debug("exposing #{plugin.name}")
        samjs[plugin.name] = plugin
      if plugin.models?.defaults?
        for model in plugin.models.defaults
          unless model.isExisting?
            throw new Error("default models need 'isExisting' function'")
      samjs._plugins.push plugin
    samjs.lifecycle.plugins samjs._plugins
    samjs.debug.plugins("finished")
    samjs.expose.options()
    return samjs
