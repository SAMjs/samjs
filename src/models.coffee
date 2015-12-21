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
  samjs.models = (models...) ->
    samjs.helper.inOrder("models")
    models = samjs.helper.parseSplats(models)
    samjs.lifecycle.beforeModels models
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
    samjs.lifecycle.models models
    samjs.debug.models("finished")
    samjs.expose.startup()
    return samjs
