# out: ../lib/models.js
module.exports = (samjs) ->
  class Model
    constructor: (options) ->
      throw new Error("can't create empty model") unless options?
      throw new Error("model needs 'name'") unless options.name?
      if options.interfaces? and not samjs.util.isObject options.interfaces
        throw new Error("model #{options.name}.interfaces need to be an object")
      if options.isRequired
        unless options.installInterface? and
            samjs.util.isFunction options.installInterface
          throw new Error("model #{options.name} needs 'installInterface'")
        unless options.test? and samjs.util.isFunction options.test
          throw new Error("model #{options.name} needs 'test'")
      samjs.helper.merge(dest:@,src:options,overwrite:true)
      @class = "Model"
      @isRequired ?= false
      @removeInterface ?= {}
    exposeInterfaces: (name) =>
      exposeInterface = (itf, name) ->
        samjs.io.of("/#{name}").on "connection", itf
        return -> samjs.io.of("/#{name}").removeListener "connection", itf
      exposeInterfaces = (interfaces, name) =>
        @removeInterface[name] ?= []
        if samjs.util.isArray interfaces
          for itf in interfaces
            @removeInterface[name].push exposeInterface(itf.bind(@), name)
        else
          @removeInterface[name].push exposeInterface(interfaces.bind(@), name)
      if name
        exposeInterfaces(@interfaces[name], name)
      else
        for name, interfaces of @interfaces
          exposeInterfaces(interfaces, name)
      return @
  samjs.models = (models...) ->
    samjs.helper.inOrder("models")
    models = samjs.helper.parseSplats(models)
    samjs.debug.models("emitting 'beforeModels'")
    samjs.emit "beforeModels", models
    samjs.debug.models("processing")
    createModel = (model) ->
      if model?
        if samjs.util.isFunction model
          model = model(samjs)
        if model.db? and samjs[model.db]?.processModel?
          model = samjs[model.db].processModel.bind(samjs[model.db])(model)
        model = new Model(model)
        samjs.debug.models "setting models.#{model.name}"
        samjs.models[model.name] = model
    for model in models
      createModel(model)
    for plugin in samjs._plugins
      if plugin.models?
        for model in plugin.models
          unless model.isExisting(models) or samjs.models[model.name]?
            createModel(model)
    samjs.debug.models("emitting 'models'")
    samjs.emit "models", models
    samjs.debug.models("finished")
    samjs.expose.startup()
    return samjs
