(function() {
  var EventEmitter, connections, init, load;

  load = function(name) {
    var resolved;
    resolved = require.resolve(name);
    if (require.cache[resolved]) {
      delete require.cache[resolved];
    }
    return require(name);
  };

  EventEmitter = require("events").EventEmitter;

  connections = [];

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
    samjs.bootstrap = function(options, cb) {
      var io, listen, reload;
      io = null;
      listen = function() {
        var server;
        server = samjs.io.httpServer;
        if (server == null) {
          server = samjs.io;
        }
        return server.listen(options.port, options.host, function() {
          var str;
          if (options.host) {
            str = "http://" + options.host + ":" + options.port + "/";
          } else {
            str = "port: " + options.port;
          }
          return console.log("samjs server listening on " + str);
        });
      };
      if (cb == null) {
        cb = options;
        options = {};
      }
      options = Object.assign({
        port: 8080,
        dev: process.env.NODE_ENV !== "production"
      }, options);
      cb(samjs);
      samjs.state.onceStarted.then(function() {
        listen();
        if (options.dev) {
          io = samjs.io;
          return samjs.io.httpServer.on("connection", function(con) {
            connections.push(con);
            return con.on("close", function() {
              return connections.splice(connections.indexOf(con), 1);
            });
          });
        }
      });
      if (options.dev) {
        reload = function(resolve, reject) {
          var e;
          samjs.reset();
          samjs.io = io;
          try {
            cb(samjs);
            resolve(samjs);
          } catch (error) {
            e = error;
            reject(e);
          }
          return samjs.state.onceStarted.then(listen);
        };
        samjs.reload = function() {
          return new samjs.Promise(function(resolve, reject) {
            var con, i, len, ref;
            if (((ref = samjs.io) != null ? ref.httpServer : void 0) != null) {
              samjs.io.httpServer.once("close", reload.bind(null, resolve, reject));
              for (i = 0, len = connections.length; i < len; i++) {
                con = connections[i];
                con.destroy();
              }
              samjs.io.httpServer.close();
              samjs.io.engine.close();
              return samjs.io.close();
            } else {
              return reload(resolve);
            }
          });
        };
      }
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
