(function() {
  var slice = [].slice;

  module.exports = function(samjs) {
    var Model;
    Model = (function() {
      function Model(options) {
        if (options == null) {
          throw new Error("can't create empty model");
        }
        if (options.name == null) {
          throw new Error("model needs 'name'");
        }
        if ((options.interfaces != null) && !samjs.util.isObject(options.interfaces)) {
          throw new Error("model " + options.name + ".interfaces need to be an object");
        }
        if (options.isRequired) {
          if (!((options.installInterface != null) && samjs.util.isFunction(options.installInterface))) {
            throw new Error("model " + options.name + " needs 'installInterface'");
          }
          if (!((options.test != null) && samjs.util.isFunction(options.test))) {
            throw new Error("model " + options.name + " needs 'test'");
          }
        }
        samjs.helper.merge({
          dest: this,
          src: options,
          overwrite: true
        });
        this["class"] = "Model";
        if (this.isRequired == null) {
          this.isRequired = false;
        }
        if (this.removeInterface == null) {
          this.removeInterface = {};
        }
      }

      return Model;

    })();
    return samjs.models = function() {
      var createModel, i, j, k, len, len1, len2, model, models, plugin, ref, ref1;
      models = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      samjs.helper.inOrder("models");
      models = samjs.helper.parseSplats(models);
      samjs.debug.models("emitting 'beforeModels'");
      samjs.emit("beforeModels", models);
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
          model = new Model(model);
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
            if (!(model.isExisting(models) || (samjs.models[model.name] != null))) {
              createModel(model);
            }
          }
        }
      }
      samjs.debug.models("emitting 'models'");
      samjs.emit("models", models);
      samjs.debug.models("finished");
      samjs.expose.startup();
      return samjs;
    };
  };

}).call(this);
