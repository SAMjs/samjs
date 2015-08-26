(function() {
  var io;

  io = require("socket.io");

  module.exports = function(samjs) {
    return samjs.startup = function(server) {
      var install;
      if (samjs.started != null) {
        throw new Error("already started up, shutdown first");
      }
      samjs.debug.startup("emitting 'beforeStartup'");
      samjs.emit("beforeStartup", server);
      samjs.debug.startup("processing");
      if (server) {
        samjs.debug.startup("got server");
        samjs.io = io(server);
      } else {
        samjs.debug.startup("creating httpServer");
        samjs.io = io();
      }
      samjs.debug.startup("checking installation");
      install = require("./install")(samjs);
      samjs.started = samjs.state.ifConfigured().then(function() {
        return samjs.debug.startup("already configured");
      })["catch"](install.configure).then(function() {
        var i, len, plugin, ref, required;
        samjs.debug.startup("starting plugins");
        required = [];
        ref = samjs._plugins;
        for (i = 0, len = ref.length; i < len; i++) {
          plugin = ref[i];
          if ((plugin.startup != null) && samjs.util.isFunction(plugin.startup)) {
            required.push(plugin.startup());
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
        return samjs.debug.startup("already installed");
      })["catch"](install.install).then(install.finish).then(function() {
        samjs.debug.startup("exposing configuration");
        return samjs.io.of("/config").on("connection", require("./configsInterface")(samjs));
      }).then(function() {
        var listener, model, name, ref, results;
        samjs.debug.startup("exposing models");
        ref = samjs.models;
        results = [];
        for (name in ref) {
          model = ref[name];
          results.push((function() {
            var ref1, results1;
            ref1 = model.interfaces;
            results1 = [];
            for (name in ref1) {
              listener = ref1[name];
              results1.push(samjs.io.of("/" + name).on("connection", listener.bind(model)));
            }
            return results1;
          })());
        }
        return results;
      }).then(function() {
        samjs.debug.startup("emitting 'startup'");
        samjs.emit("startup");
        samjs.debug.startup("finished");
        samjs.io.of("/").emit("loaded");
        samjs.expose.shutdown();
        return samjs;
      });
      return samjs;
    };
  };

}).call(this);
