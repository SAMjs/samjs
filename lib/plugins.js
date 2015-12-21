(function() {
  var slice = [].slice;

  module.exports = function(samjs) {
    var validate, validateHelper;
    validateHelper = function(plugin, prop, type) {
      var e, i, len, obj, p, path;
      path = prop.split(".");
      obj = plugin;
      for (i = 0, len = path.length; i < len; i++) {
        p = path[i];
        obj = obj[p];
        if (obj == null) {
          return;
        }
      }
      if (!samjs.util["is" + type](obj)) {
        e = "plugin." + prop + " must be a " + type;
        if (plugin.name) {
          e += " - plugin: " + plugin.name;
        }
        throw new Error(e);
      }
    };
    validate = function(plugin) {
      var i, len, model, name, ref, ref1;
      if (!samjs.util.isObject(plugin)) {
        throw new Error("plugin needs to be an object or function");
      }
      if (!plugin.debug) {
        if (plugin.name) {
          plugin.debug = samjs.debug(plugin.name);
        } else {
          plugin.debug = function() {};
        }
      }
      validateHelper(plugin, "debug", "Function");
      validateHelper(plugin, "name", "String");
      validateHelper(plugin, "obj", "Object");
      validateHelper(plugin, "options", "Object");
      validateHelper(plugin, "configs", "Array");
      validateHelper(plugin, "models", "Object");
      validateHelper(plugin, "models.defaults", "Object");
      if (((ref = plugin.models) != null ? ref.defaults : void 0) != null) {
        name = "";
        if ((plugin != null ? plugin.name : void 0) != null) {
          name = " - plugin: " + plugin.name;
        }
        ref1 = plugin.models.defaults;
        for (i = 0, len = ref1.length; i < len; i++) {
          model = ref1[i];
          if (model.name == null) {
            throw new Error("default models need a 'name'" + name);
          }
          if (!samjs.util.isString(model.name)) {
            throw new Error("default models name needs to be a string" + name);
          }
          if (model.isExisting == null) {
            throw new Error(("default model " + model.name + " need a 'isExisting' function") + name);
          }
          if (!samjs.util.isFunction(model.isExisting)) {
            throw new Error("default models 'isExisting' needs to be a function" + name);
          }
        }
      }
      validateHelper(plugin, "startup", "Function");
      return validateHelper(plugin, "shutdown", "Function");
    };
    return samjs.plugins = function() {
      var i, j, len, len1, model, plugin, plugins, ref, ref1;
      plugins = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      samjs.helper.inOrder("plugins");
      plugins = samjs.helper.parseSplats(plugins);
      samjs._plugins = [];
      samjs.lifecycle.beforePlugins(plugins);
      samjs.debug.plugins("processing");
      for (i = 0, len = plugins.length; i < len; i++) {
        plugin = plugins[i];
        if (samjs.util.isFunction(plugin)) {
          plugin = plugin(samjs);
          if (!samjs.util.isObject(plugin)) {
            throw new Error("generator function for plugin should return an object");
          }
        }
        validate(plugin);
        if ((plugin.name != null) && (plugin.obj != null)) {
          plugin.debug("exposing " + plugin.name);
          samjs[plugin.name] = plugin.obj;
        }
        if (((ref = plugin.models) != null ? ref.defaults : void 0) != null) {
          ref1 = plugin.models.defaults;
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            model = ref1[j];
            if (model.isExisting == null) {
              throw new Error("default models need 'isExisting' function'");
            }
          }
        }
        samjs._plugins.push(plugin);
      }
      samjs.lifecycle.plugins(samjs._plugins);
      samjs.debug.plugins("finished");
      samjs.expose.options();
      return samjs;
    };
  };

}).call(this);
