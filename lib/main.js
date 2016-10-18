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
    samjs.props = ["options", "configs", "models", "startup", "shutdown", "started"];
    samjs.state = {};
    samjs.reset = function() {
      var i, len, prop, ref, ref1, ref2, socket, socketid;
      samjs.debug.core("resetting samjs instance");
      if ((ref = samjs.options) != null) {
        if (typeof ref.setDefaults === "function") {
          ref.setDefaults();
        }
      }
      ref1 = samjs.props;
      for (i = 0, len = ref1.length; i < len; i++) {
        prop = ref1[i];
        samjs[prop] = null;
      }
      if (samjs.io != null) {
        ref2 = samjs.io.sockets.connected;
        for (socketid in ref2) {
          socket = ref2[socketid];
          socket.removeAllListeners();
        }
        samjs.io.of("/").removeAllListeners();
        samjs.io = null;
      }
      samjs.lifecycle.reset();
      samjs.removeAllListeners();
      samjs.state.reset();
      samjs.expose.plugins();
      return samjs;
    };
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
