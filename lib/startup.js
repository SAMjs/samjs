(function() {
  module.exports = function(samjs) {
    return samjs.startup = function(server) {
      if (samjs.started != null) {
        throw new Error("already started up, shutdown first");
      }
      if (server != null) {
        samjs.server = server;
      }
      samjs.lifecycle.startupInitialization();
      samjs.debug.startup("processing");
      if (!((samjs.io != null) || samjs.noServer)) {
        if (samjs.server) {
          samjs.debug.startup("got server");
          samjs.io = samjs.socketio(samjs.server);
        } else {
          samjs.debug.startup("creating httpServer");
          samjs.io = samjs.socketio();
        }
      }
      samjs.state.startup = samjs.lifecycle.beforeStartup().then(function() {
        var install;
        samjs.debug.startup("checking installation");
        install = require("./install")(samjs);
        return samjs.state.ifConfigured().then(function() {
          samjs.lifecycle.configured();
          return samjs.debug.startup("already configured");
        })["catch"]((function(e) {
          return e.message === "not configured";
        }), install.configure).then(function() {
          var i, len, plugin, ref, required;
          samjs.debug.startup("starting plugins");
          required = [];
          ref = samjs._plugins;
          for (i = 0, len = ref.length; i < len; i++) {
            plugin = ref[i];
            if ((plugin.startup != null) && samjs.util.isFunction(plugin.startup)) {
              required.push(plugin.startup.bind(plugin)());
            }
          }
          return samjs.Promise.all(required);
        }).then(function() {
          return samjs.debug.startup("plugins started");
        }).then(function() {
          var model, name, ref, ref1, required;
          samjs.debug.startup("starting models");
          required = [];
          ref = samjs.models;
          for (name in ref) {
            model = ref[name];
            required.push((ref1 = model.startup) != null ? ref1.bind(model)() : void 0);
          }
          return samjs.Promise.all(required);
        }).then(function() {
          return samjs.debug.startup("models started");
        }).then(samjs.state.ifInstalled).then(function() {
          samjs.lifecycle.installed();
          return samjs.debug.startup("already installed");
        })["catch"]((function(e) {
          return e.message === "not installed";
        }), install.install).then(install.finish).then(samjs.lifecycle.beforeExposing).then(function() {
          samjs.debug.startup("exposing interfaces");
          return samjs.interfaces.expose();
        }).then(function() {
          samjs.lifecycle.started();
          samjs.debug.startup("finished");
          samjs.io.of("/").emit("loaded");
          samjs.expose.shutdown();
          return samjs;
        });
        return samjs.lifecycle.startup();
      });
      return samjs;
    };
  };

}).call(this);
