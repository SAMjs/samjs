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
            var config, name, ref, results;
            samjs.debug.configs("socket connected");
            ref = samjs.configs;
            results = [];
            for (name in ref) {
              config = ref[name];
              results.push(listener(socket, config));
            }
            return results;
          }
        };
        this._closers = {};
      }

      Interfaces.prototype.add = function(name, itf) {
        return this._interfaces[name] = ift;
      };

      Interfaces.prototype.close = function(name) {
        var closer, ref, results;
        if (name) {
          if (samjs.util.isFunction(this._closers[name] != null)) {
            return this._closers[name]();
          }
        } else {
          ref = this._closers;
          results = [];
          for (name in ref) {
            closer = ref[name];
            results.push(closer());
          }
          return results;
        }
      };

      Interfaces.prototype.expose = function(name) {
        var exposeInterface, exposeInterfaces, i, interfaces, j, len, len1, model, modelname, plugin, ref, ref1, ref2, ref3, ref4, ref5, ref6;
        exposeInterface = function(itf, name) {
          samjs.io.of("/" + name).on("connection", itf);
          return function() {
            return samjs.io.of("/" + name).removeListener("connection", itf);
          };
        };
        exposeInterfaces = (function(_this) {
          return function(interfaces, name) {
            var base, i, itf, len, results;
            if ((base = _this._closers)[name] == null) {
              base[name] = [];
            }
            if (samjs.util.isArray(interfaces)) {
              results = [];
              for (i = 0, len = interfaces.length; i < len; i++) {
                itf = interfaces[i];
                results.push(_this._closers[name].push(exposeInterface(itf, name)));
              }
              return results;
            } else {
              return _this._closers[name].push(exposeInterface(interfaces, name));
            }
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
                  exposeInterfaces(model.interfaces, name);
                }
              } else if (model.interfaces[name] != null) {
                exposeInterfaces(model.interfaces[name], name);
              }
            }
            ref1 = samjs._plugins;
            for (i = 0, len = ref1.length; i < len; i++) {
              plugin = ref1[i];
              if (plugin.interfaces != null) {
                if (samjs.util.isArray(plugin.interfaces)) {
                  if (plugin.name === name) {
                    exposeInterfaces(plugin.interfaces, name);
                  }
                } else if (plugin.interfaces[name] != null) {
                  exposeInterfaces(plugin.interfaces[name], name);
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
              exposeInterfaces(model.interfaces, modelname);
            } else {
              ref4 = model.interfaces;
              for (name in ref4) {
                interfaces = ref4[name];
                exposeInterfaces(interfaces, name);
              }
            }
          }
          ref5 = samjs._plugins;
          for (j = 0, len1 = ref5.length; j < len1; j++) {
            plugin = ref5[j];
            if (plugin.interfaces != null) {
              if (samjs.util.isArray(plugin.interfaces)) {
                exposeInterfaces(plugin.interfaces, plugin.name);
              } else {
                ref6 = plugin.interfaces;
                for (name in ref6) {
                  interfaces = ref6[name];
                  exposeInterfaces(interfaces, name);
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
