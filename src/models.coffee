# out: ../lib/models.js
module.exports = (samjs) ->
  validateModel = (model) ->
    throw new Error("can't create empty model") unless model?
    throw new Error("model needs 'name'") unless model.name?
    if model.interfaces? and not samjs.util.isObject model.interfaces
      throw new Error("model #{model.name}.interfaces need to be an object")
    if model.isRequired
      unless model.installInterface? and
          samjs.util.isFunction model.installInterface
        throw new Error("model #{model.name} needs 'installInterface'")
      unless model.test? and samjs.util.isFunction model.test
        throw new Error("model #{model.name} needs 'test'")
    model.class = "Model"
    model.isRequired ?= false
    return model

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
        model = validateModel(model)
        samjs.debug.models "setting models.#{model.name}"
        samjs.models[model.name] = model
    for model in models
      createModel(model)
    for plugin in samjs._plugins
      if plugin.models?
        for model in plugin.models
          unless samjs.models[model.name]?
            createModel(model)
    samjs.lifecycle.models models
    samjs.debug.models("finished")
    samjs.expose.startup()
    return samjs
