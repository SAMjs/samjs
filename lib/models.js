(function() {
  var slice = [].slice;

  module.exports = function(samjs) {
    var validateModel;
    validateModel = function(model) {
      if (model == null) {
        throw new Error("can't create empty model");
      }
      if (model.name == null) {
        throw new Error("model needs 'name'");
      }
      if ((model.interfaces != null) && !samjs.util.isObject(model.interfaces)) {
        throw new Error("model " + model.name + ".interfaces need to be an object");
      }
      if (model.isRequired) {
        if (!((model.installInterface != null) && samjs.util.isFunction(model.installInterface))) {
          throw new Error("model " + model.name + " needs 'installInterface'");
        }
        if (!((model.test != null) && samjs.util.isFunction(model.test))) {
          throw new Error("model " + model.name + " needs 'test'");
        }
      }
      model["class"] = "Model";
      if (model.isRequired == null) {
        model.isRequired = false;
      }
      return model;
    };
    return samjs.models = function() {
      var createModel, i, j, k, len, len1, len2, model, models, plugin, ref, ref1;
      models = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      samjs.helper.inOrder("models");
      models = samjs.helper.parseSplats(models);
      samjs.lifecycle.beforeModels(models);
      samjs.debug.models("processing");
      createModel = function(model) {
        var ref;
        if (model != null) {
          if (samjs.util.isFunction(model)) {
            model = model(samjs);
          }
          if ((model.db != null) && (((ref = samjs[model.db]) != null ? ref.processModel : void 0) != null)) {
            model = samjs[model.db].processModel.bind(samjs[model.db])(model);
          }
          model = validateModel(model);
          samjs.debug.models("setting models." + model.name);
          return samjs.models[model.name] = model;
        }
      };
      for (i = 0, len = models.length; i < len; i++) {
        model = models[i];
        createModel(model);
      }
      ref = samjs._plugins;
      for (j = 0, len1 = ref.length; j < len1; j++) {
        plugin = ref[j];
        if (plugin.models != null) {
          ref1 = plugin.models;
          for (k = 0, len2 = ref1.length; k < len2; k++) {
            model = ref1[k];
            if (samjs.models[model.name] == null) {
              createModel(model);
            }
          }
        }
      }
      samjs.lifecycle.models(models);
      samjs.debug.models("finished");
      samjs.expose.startup();
      return samjs;
    };
  };

}).call(this);
