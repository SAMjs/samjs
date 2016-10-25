(function() {
  var EventEmitter, init, load;

  load = function(name) {
    var resolved;
    resolved = require.resolve(name);
    if (require.cache[resolved]) {
      delete require.cache[resolved];
    }
    return require(name);
  };

  EventEmitter = require("events").EventEmitter;

  init = function() {
    var samjs;
    samjs = new EventEmitter();
    samjs.Promise = require("bluebird");
    samjs.socketio = require("socket.io");
    samjs.util = require("core-util-is");
    samjs.debug = require("./debug");
    samjs.order = ["plugins", "options", "configs", "models", "startup", "shutdown"];
    samjs.props = ["_plugins", "options", "configs", "models", "startup", "shutdown", "started"];
    samjs.state = {};
    samjs.removeAllSocketIOListeners = function() {
      var id, nid, nsp, ref, results, socket;
      samjs.debug.core("remove all socketIO listeners");
      if (samjs.io != null) {
        ref = samjs.io.nsps;
        results = [];
        for (nid in ref) {
          nsp = ref[nid];
          nsp.removeAllListeners();
          results.push((function() {
            var ref1, results1;
            ref1 = nsp.sockets;
            results1 = [];
            for (id in ref1) {
              socket = ref1[id];
              results1.push(socket.removeAllListeners());
            }
            return results1;
          })());
        }
        return results;
      }
    };
    samjs.reset = function() {
      var i, j, len, len1, plugin, prop, ref, ref1, ref2, ref3, ref4;
      samjs.debug.core("resetting samjs instance");
      if ((ref = samjs.options) != null) {
        if (typeof ref.setDefaults === "function") {
          ref.setDefaults();
        }
      }
      if (samjs._plugins != null) {
        samjs.debug.core("shuting down all plugins");
        ref1 = samjs._plugins;
        for (i = 0, len = ref1.length; i < len; i++) {
          plugin = ref1[i];
          if ((ref2 = plugin.shutdown) != null) {
            ref2.bind(samjs)();
          }
        }
      }
      if ((ref3 = samjs.interfaces) != null) {
        ref3.reset();
      }
      ref4 = samjs.props;
      for (j = 0, len1 = ref4.length; j < len1; j++) {
        prop = ref4[j];
        samjs[prop] = null;
      }
      samjs.removeAllSocketIOListeners();
      samjs.io = null;
      samjs.lifecycle.reset();
      samjs.removeAllListeners();
      samjs.state.reset();
      samjs.expose.plugins();
      return samjs;
    };
    samjs.bootstrap = require("./bootstrap")(samjs);
    require("./helper")(samjs);
    require("./state")(samjs);
    require("./interfaces")(samjs);
    samjs.expose = {
      plugins: function() {
        samjs.debug.core("exposing plugins");
        return require("./plugins")(samjs);
      },
      options: function() {
        samjs.debug.core("exposing options");
        return require("./options")(samjs);
      },
      configs: function() {
        samjs.debug.core("exposing config");
        return load("./configs")(samjs);
      },
      models: function() {
        samjs.debug.core("exposing models");
        return require("./models")(samjs);
      },
      startup: function() {
        samjs.debug.core("exposing startup");
        return require("./startup")(samjs);
      },
      shutdown: function() {
        samjs.debug.core("exposing shutdown");
        return require("./shutdown")(samjs);
      }
    };
    samjs.expose.plugins();
    return samjs;
  };

  module.exports = init();

}).call(this);
