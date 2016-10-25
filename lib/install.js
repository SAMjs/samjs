(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = function(samjs) {
    var Install, debug, responder;
    debug = samjs.debug.install;
    responder = function(trigger, response) {
      var listener, ref, results, socket, socketid;
      listener = function(socket) {
        var respond;
        respond = function(request) {
          if ((request != null ? request.token : void 0) != null) {
            debug("responding on " + trigger + " with " + response);
            return socket.emit(trigger + "." + request.token, {
              success: response !== false,
              content: response
            });
          }
        };
        return socket.on(trigger, respond);
      };
      debug("setting " + response + " responder on " + trigger);
      samjs.io.on("connection", listener);
      ref = samjs.io.sockets.connected;
      results = [];
      for (socketid in ref) {
        socket = ref[socketid];
        results.push(listener(socket));
      }
      return results;
    };
    return new (Install = (function() {
      function Install() {
        this.configure = bind(this.configure, this);
      }

      Install.prototype.configure = function() {
        samjs.lifecycle.beforeConfigure();
        debug("exposing configuration");
        samjs.io.of("/configure").on("connection", (function(_this) {
          return function(socket) {
            var config, name, ref, results;
            debug("socket connected");
            ref = samjs.configs;
            results = [];
            for (name in ref) {
              config = ref[name];
              if (config.isRequired) {
                _this.configListener(socket, config);
                if (config.installInterface != null) {
                  results.push(config.installInterface.bind(config)(socket));
                } else {
                  results.push(void 0);
                }
              } else {
                results.push(void 0);
              }
            }
            return results;
          };
        })(this));
        responder("installation", "configure");
        samjs.io.emit("configure");
        samjs.lifecycle.configure();
        return new samjs.Promise(function(resolve) {
          return samjs.state.onceConfigured.then(function() {
            samjs.removeAllSocketIOListeners();
            return resolve();
          });
        });
      };

      Install.prototype.configListener = function(socket, config) {
        debug("listening on " + config.name + ".test");
        socket.on(config.name + ".test", function(request) {
          if (((request != null ? request.content : void 0) != null) && (request.token != null)) {
            debug("testing on " + config.name + ".test: " + request.content);
            return config._test(request.content).then(function(info) {
              return {
                success: true,
                content: info
              };
            })["catch"](function(err) {
              return {
                success: false,
                content: err != null ? err.message : void 0
              };
            }).then(function(response) {
              return socket.emit(config.name + ".test." + request.token, response);
            });
          }
        });
        debug("listening on " + config.name + ".get");
        socket.on(config.name + ".get", function(request) {
          if ((request != null ? request.token : void 0) != null) {
            debug("getting on " + config.name + ".get");
            return config._get().then(function(response) {
              return {
                success: true,
                content: response
              };
            })["catch"](function(err) {
              return {
                success: false,
                content: err != null ? err.message : void 0
              };
            }).then(function(response) {
              return socket.emit(config.name + ".get." + request.token, response);
            });
          }
        });
        debug("listening on " + config.name + ".set");
        return socket.on(config.name + ".set", function(request) {
          debug("setting on " + config.name + ".set: " + request.content);
          if (((request != null ? request.content : void 0) != null) && (request.token != null)) {
            return config._set(request.content)["return"](config).call("_get").then(function(response) {
              socket.broadcast.emit("update", config.name);
              samjs.state.ifConfigured(config.name).then(function() {
                debug("config installed completely");
                return samjs.lifecycle.configured();
              })["catch"](function() {});
              return {
                success: true,
                content: response
              };
            })["catch"](function(err) {
              return {
                success: false,
                content: err != null ? err.message : void 0
              };
            }).then(function(response) {
              return socket.emit(config.name + ".set." + request.token, response);
            });
          }
        });
      };

      Install.prototype.install = function() {
        samjs.lifecycle.beforeInstall();
        debug("exposing install");
        samjs.io.of("/install").on("connection", function(socket) {
          var model, name, ref, results;
          ref = samjs.models;
          results = [];
          for (name in ref) {
            model = ref[name];
            if (model.isRequired) {
              results.push(model.installInterface.bind(model)(socket));
            } else {
              results.push(void 0);
            }
          }
          return results;
        });
        responder("installation", "install");
        samjs.io.of("/configure").emit("done");
        samjs.io.emit("install");
        samjs.lifecycle.install();
        return new samjs.Promise(function(resolve) {
          return samjs.state.onceInstalled.then(function() {
            samjs.removeAllSocketIOListeners();
            return resolve();
          });
        });
      };

      Install.prototype.finish = function() {
        return new samjs.Promise(function(resolve) {
          if (samjs.io == null) {
            return resolve();
          }
          responder("installation", false);
          samjs.io.of("/configure").emit("done");
          samjs.io.of("/install").emit("done");
          return setTimeout((function() {
            var ref;
            if (((ref = samjs.io) != null ? ref.engine : void 0) != null) {
              debug("issuing reconnect of all connected sockets");
              samjs.removeAllSocketIOListeners();
              samjs.io.engine.close();
            }
            return resolve();
          }), 500);
        });
      };

      return Install;

    })());
  };

}).call(this);
