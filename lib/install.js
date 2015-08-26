(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = function(samjs) {
    var Install, debug, responder;
    debug = samjs.debug.install;
    responder = function(trigger, response) {
      var listener, ref, remover, socket, socketid;
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
      remover = function() {
        var ref, results, socket, socketid;
        debug("removing responder on " + trigger + " (" + response + ")");
        samjs.io.of("/").removeListener("connection", listener);
        ref = samjs.io.sockets.connected;
        results = [];
        for (socketid in ref) {
          socket = ref[socketid];
          results.push(socket.removeAllListeners(trigger));
        }
        return results;
      };
      debug("setting " + response + " responder on " + trigger);
      samjs.io.on("connection", listener);
      ref = samjs.io.sockets.connected;
      for (socketid in ref) {
        socket = ref[socketid];
        listener(socket);
      }
      return remover;
    };
    return new (Install = (function() {
      function Install() {
        this.configure = bind(this.configure, this);
      }

      Install.prototype.configure = function() {
        var deleteResponder, disposes;
        debug("emitting beforeConfigure");
        samjs.emit("beforeConfigure");
        debug("exposing configuration");
        disposes = [];
        samjs.io.of("/configure").on("connection", (function(_this) {
          return function(socket) {
            var config, name, ref, results;
            debug("socket connected");
            ref = samjs.configs;
            results = [];
            for (name in ref) {
              config = ref[name];
              if (config.isRequired) {
                results.push(disposes.push(_this.configListener(socket, config)));
              } else {
                results.push(void 0);
              }
            }
            return results;
          };
        })(this));
        disposes.push(function() {
          return samjs.io.of("/configure").removeAllListeners("connection");
        });
        deleteResponder = responder("installation", "configure");
        samjs.io.emit("configure");
        debug("emitting configure");
        samjs.emit("configure");
        return new samjs.Promise(function(resolve) {
          return samjs.once("configured", function() {
            var dispose, i, len;
            debug("configured");
            for (i = 0, len = disposes.length; i < len; i++) {
              dispose = disposes[i];
              dispose();
            }
            deleteResponder();
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
        socket.on(config.name + ".set", function(request) {
          debug("setting on " + config.name + ".set: " + request.content);
          if (((request != null ? request.content : void 0) != null) && (request.token != null)) {
            return config._set(request.content)["return"](config).call("_get").then(function(response) {
              socket.broadcast.emit("update", config.name);
              samjs.state.ifConfigured(config.name).then(function() {
                debug("config installed completely");
                return samjs.emit("configured");
              });
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
        return function() {
          if (socket != null) {
            socket.removeAllListeners(config.name + ".test");
            socket.removeAllListeners(config.name + ".get");
            return socket.removeAllListeners(config.name + ".set");
          }
        };
      };

      Install.prototype.install = function() {
        var deleteResponder, disposes, model, name, ref;
        debug("emitting beforeInstall");
        samjs.emit("beforeInstall");
        debug("exposing install");
        disposes = [];
        ref = samjs.models;
        for (name in ref) {
          model = ref[name];
          if (model.isRequired) {
            samjs.io.of("/install").on("connection", function(socket) {
              var disposer;
              disposer = model.installInterface.bind(model)(socket);
              if (!samjs.util.isFunction(disposer)) {
                throw new Error("installInterface needs to return a dispose function model: " + name);
              }
              return disposes.push(disposer);
            });
            disposes.push(function() {
              return samjs.io.of("/install").removeAllListeners("connection");
            });
          }
        }
        deleteResponder = responder("installation", "install");
        samjs.io.of("/configure").emit("done");
        samjs.io.emit("install");
        debug("emitting install");
        samjs.emit("install");
        return new samjs.Promise(function(resolve) {
          return samjs.on("checkInstalled", function() {
            var dispose, i, len;
            if (samjs.state.ifInstalled()) {
              debug("emitting installed");
              samjs.emit("installed");
              for (i = 0, len = disposes.length; i < len; i++) {
                dispose = disposes[i];
                dispose();
              }
              deleteResponder();
              samjs.io.of("/install").emit("done");
              return resolve();
            }
          });
        });
      };

      Install.prototype.finish = function() {
        var i, len, ref, socket;
        responder("installation", false);
        samjs.io.of("/configure").emit("done");
        samjs.io.of("/install").emit("done");
        if (samjs.io.engine != null) {
          debug("issuing reconnect of all connected sockets");
          ref = samjs.io.nsps["/"].sockets;
          for (i = 0, len = ref.length; i < len; i++) {
            socket = ref[i];
            socket.onclose("reconnect");
          }
          return samjs.io.engine.close();
        }
      };

      return Install;

    })());
  };

}).call(this);
