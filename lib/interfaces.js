(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = function(samjs) {
    var Interfaces, listener;
    listener = function(socket, config) {
      samjs.debug.configs("listening on " + config.name + ".test");
      socket.on(config.name + ".test", function(request) {
        if (((request != null ? request.content : void 0) != null) && (request.token != null)) {
          return config.test(request.content, socket.client).then(function(info) {
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
      samjs.debug.configs("listening on " + config.name + ".get");
      socket.on(config.name + ".get", function(request) {
        if ((request != null ? request.token : void 0) != null) {
          return config.get(socket.client).then(function(response) {
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
      samjs.debug.configs("listening on " + config.name + ".set");
      return socket.on(config.name + ".set", function(request) {
        if (((request != null ? request.content : void 0) != null) && (request.token != null)) {
          return config.set(request.content, socket.client).then(function(response) {
            socket.broadcast.emit("updated", config.name);
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
    return samjs.interfaces = new (Interfaces = (function() {
      function Interfaces() {
        this.expose = bind(this.expose, this);
        this.close = bind(this.close, this);
        this._interfaces = {
          config: function(socket) {
            var config, name, ref;
            samjs.debug.configs("socket connected");
            ref = samjs.configs;
            for (name in ref) {
              config = ref[name];
              listener(socket, config);
            }
            return socket.on("disconnect", function() {
              return samjs.debug.configs("socket disconnected");
            });
          }
        };
        this._closers = {};
      }

      Interfaces.prototype.add = function(name, itf) {
        return this._interfaces[name] = ift;
      };

      Interfaces.prototype.close = function(name) {
        var close, closers, ref;
        close = function(closers) {
          var i, len, results;
          results = [];
          for (i = 0, len = closers.length; i < len; i++) {
            close = closers[i];
            results.push(close());
          }
          return results;
        };
        if (name) {
          if (this._closers[name] != null) {
            close(this._closers[name]);
          }
        } else {
          ref = this._closers;
          for (name in ref) {
            closers = ref[name];
            close(closers);
          }
        }
        return null;
      };

      Interfaces.prototype.expose = function(name) {
        var exposeInterfaces, i, interfaces, j, len, len1, model, modelname, plugin, ref, ref1, ref2, ref3, ref4, ref5, ref6;
        exposeInterfaces = (function(_this) {
          return function(interfaces, name, binding) {
            var base;
            if ((base = _this._closers)[name] == null) {
              base[name] = [];
            }
            if (!samjs.util.isArray(interfaces)) {
              interfaces = [interfaces];
            }
            listener = function(socket) {
              var i, itf, len, results;
              results = [];
              for (i = 0, len = interfaces.length; i < len; i++) {
                itf = interfaces[i];
                results.push(itf.bind(binding)(socket));
              }
              return results;
            };
            samjs.io.of("/" + name).on("connection", listener);
            return _this._closers[name].push(function() {
              return samjs.io.of("/" + name).removeListener("connection", listener);
            });
          };
        })(this);
        if (name) {
          if (this._interfaces[name] != null) {
            exposeInterfaces(this._interfaces[name], name);
          } else {
            ref = samjs.models;
            for (modelname in ref) {
              model = ref[modelname];
              if (samjs.util.isArray(model.interfaces)) {
                if (model.name === name) {
                  exposeInterfaces(model.interfaces, name, model);
                }
              } else if (model.interfaces[name] != null) {
                exposeInterfaces(model.interfaces[name], name, model);
              }
            }
            ref1 = samjs._plugins;
            for (i = 0, len = ref1.length; i < len; i++) {
              plugin = ref1[i];
              if (plugin.interfaces != null) {
                if (samjs.util.isArray(plugin.interfaces)) {
                  if (plugin.name === name) {
                    exposeInterfaces(plugin.interfaces, name, plugin);
                  }
                } else if (plugin.interfaces[name] != null) {
                  exposeInterfaces(plugin.interfaces[name], name, plugin);
                }
              }
            }
          }
        } else {
          ref2 = this._interfaces;
          for (name in ref2) {
            interfaces = ref2[name];
            exposeInterfaces(interfaces, name);
          }
          ref3 = samjs.models;
          for (modelname in ref3) {
            model = ref3[modelname];
            if (samjs.util.isArray(model.interfaces)) {
              exposeInterfaces(model.interfaces, modelname, model);
            } else {
              ref4 = model.interfaces;
              for (name in ref4) {
                interfaces = ref4[name];
                exposeInterfaces(interfaces, name, model);
              }
            }
          }
          ref5 = samjs._plugins;
          for (j = 0, len1 = ref5.length; j < len1; j++) {
            plugin = ref5[j];
            if (plugin.interfaces != null) {
              if (samjs.util.isArray(plugin.interfaces)) {
                exposeInterfaces(plugin.interfaces, plugin.name, plugin);
              } else {
                ref6 = plugin.interfaces;
                for (name in ref6) {
                  interfaces = ref6[name];
                  exposeInterfaces(interfaces, name, plugin);
                }
              }
            }
          }
        }
        return this;
      };

      return Interfaces;

    })());
  };

}).call(this);
