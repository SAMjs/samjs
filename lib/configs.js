(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    slice = [].slice;

  module.exports = function(samjs) {
    var Config, asyncHooks, fs, syncHooks;
    fs = samjs.Promise.promisifyAll(require("fs"));
    asyncHooks = ["afterGet", "afterSet", "afterTest", "after_Get", "beforeGet", "beforeSet", "beforeTest", "before_Set"];
    syncHooks = ["afterCreate", "beforeCreate"];
    Config = (function() {
      function Config(options) {
        this.set = bind(this.set, this);
        this._set = bind(this._set, this);
        this.get = bind(this.get, this);
        this._get = bind(this._get, this);
        this._getBare = bind(this._getBare, this);
        this.load = bind(this.load, this);
        var hookname, hooks, i, len, plugin, ref, ref1, ref2, ref3;
        if (!options || !options.name) {
          throw new Error("config needs 'name' property");
        }
        this.name = options.name;
        delete options.name;
        this["class"] = "Config";
        samjs.helper.initiateHooks(this, asyncHooks, syncHooks);
        ref = samjs._plugins;
        for (i = 0, len = ref.length; i < len; i++) {
          plugin = ref[i];
          if (((ref1 = plugin.hooks) != null ? ref1.configs : void 0) != null) {
            ref2 = plugin.hooks.configs;
            for (hookname in ref2) {
              hooks = ref2[hookname];
              this.addHook(hookname, hooks);
            }
          }
        }
        options = this._hooks.beforeCreate(options);
        if (options.test) {
          this._test = options.test;
          delete options.test;
        } else {
          if (options.isRequired) {
            this._test = function(data) {
              return new samjs.Promise(function(resolve, reject) {
                if (data != null) {
                  return resolve(data);
                } else {
                  return reject(data);
                }
              });
            };
          } else {
            this._test = function(data) {
              return samjs.Promise.resolve(data);
            };
          }
        }
        ref3 = options.hooks;
        for (hookname in ref3) {
          hooks = ref3[hookname];
          this.addHook(hookname, hooks);
        }
        delete options.hooks;
        samjs.helper.merge({
          dest: this,
          src: options,
          overwrite: true
        });
        if (this.isRequired == null) {
          this.isRequired = false;
        }
        this._hooks.afterCreate(this);
        return this;
      }

      Config.prototype.load = function(reader) {
        return this.loaded = reader.then((function(_this) {
          return function(data) {
            if ((data != null ? data[_this.name] : void 0) != null) {
              return _this.data = data[_this.name];
            } else {
              throw new Error("config " + _this.name + " not set");
            }
          };
        })(this));
      };

      Config.prototype._getBare = function() {
        var ref;
        if (this.data != null) {
          return samjs.Promise.resolve(this.data);
        } else if ((ref = this.loaded) != null ? ref.isPending() : void 0) {
          return this.loaded;
        } else {
          return samjs.Promise.reject(new Error("config " + this.name + " not set"));
        }
      };

      Config.prototype._get = function() {
        return this._getBare()["catch"](function() {
          return null;
        }).then(this._hooks.after_Get);
      };

      Config.prototype.get = function(client) {
        if (!this.read) {
          return samjs.Promise.reject(new Error("no permission"));
        }
        return this._hooks.beforeGet({
          client: client
        }).then(this._get).then(this._hooks.afterGet);
      };

      Config.prototype._set = function(newData) {
        return this._test(newData, this.data).then((function(_this) {
          return function() {
            return _this._hooks.before_Set({
              data: newData,
              oldData: _this.data
            });
          };
        })(this)).then((function(_this) {
          return function(arg) {
            var data;
            data = arg.data;
            newData = data;
            return fs.readFileAsync(samjs.options.config)["catch"](function() {
              return "{}";
            }).then(JSON.parse)["catch"](function() {
              return {};
            }).then(function(data) {
              data[_this.name] = newData;
              _this.data = newData;
              return fs.writeFileAsync(samjs.options.config, JSON.stringify(data));
            });
          };
        })(this)).then(this._hooks.after_Set);
      };

      Config.prototype.set = function(data, client) {
        if (!this.write) {
          return samjs.Promise.reject(new Error("no permission"));
        }
        return this._hooks.beforeSet({
          data: data,
          client: client
        }).then((function(_this) {
          return function(arg) {
            var data;
            data = arg.data;
            return _this._set(data);
          };
        })(this)).then(this._hooks.afterSet);
      };

      Config.prototype.test = function(data, client) {
        if (!this.write) {
          return samjs.Promise.reject(new Error("no permission"));
        }
        return this._hooks.beforeTest({
          data: data,
          client: client
        }).then((function(_this) {
          return function(arg) {
            var data;
            data = arg.data;
            return _this._test(data, _this.data);
          };
        })(this)).then(this._hooks.afterTest);
      };

      return Config;

    })();
    return samjs.configs = function() {
      var config, configs, createConfig, def, defaults, i, j, k, len, len1, len2, plugin, reader, ref;
      configs = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      samjs.helper.inOrder("configs");
      configs = samjs.helper.parseSplats(configs);
      samjs.lifecycle.beforeConfigs(configs);
      samjs.debug.configs("processing");
      defaults = [];
      ref = samjs._plugins;
      for (i = 0, len = ref.length; i < len; i++) {
        plugin = ref[i];
        if (plugin.configs != null) {
          plugin.debug("got configs");
          if (samjs.util.isFunction(plugin.configs)) {
            defaults = defaults.concat(plugin.configs(samjs));
          } else {
            defaults = defaults.concat(plugin.configs);
          }
        }
      }
      reader = fs.readFileAsync(samjs.options.config).then(JSON.parse)["catch"](samjs.debug.configs);
      createConfig = function(options) {
        var config;
        config = new Config(options);
        config.load(reader)["catch"](function() {
          return null;
        });
        samjs.debug.configs("setting configs." + config.name);
        return samjs.configs[config.name] = config;
      };
      for (j = 0, len1 = configs.length; j < len1; j++) {
        config = configs[j];
        createConfig(config);
      }
      for (k = 0, len2 = defaults.length; k < len2; k++) {
        def = defaults[k];
        if (samjs.configs[def.name] == null) {
          createConfig(def);
        }
      }
      samjs.lifecycle.configs(configs);
      samjs.debug.configs("finished");
      samjs.expose.models();
      return samjs;
    };
  };

}).call(this);
