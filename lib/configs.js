(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    slice = [].slice;

  module.exports = function(samjs) {
    var Config, fs;
    fs = samjs.Promise.promisifyAll(require("fs"));
    Config = (function() {
      function Config(options) {
        this._set = bind(this._set, this);
        this._get = bind(this._get, this);
        this._getBare = bind(this._getBare, this);
        this.load = bind(this.load, this);
        if (!options || !options.name) {
          throw new Error("config needs 'name' property");
        }
        if (options.test) {
          this._test = options.test;
          delete options.test;
        } else {
          this._test = function(data) {
            return samjs.Promise.resolve(data);
          };
        }
        samjs.helper.merge({
          dest: this,
          src: options,
          overwrite: true
        });
        this["class"] = "Config";
        if (this.isRequired == null) {
          this.isRequired = false;
        }
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
        });
      };

      Config.prototype._set = function(newContent) {
        return this._test(newContent).then((function(_this) {
          return function() {
            return fs.readFileAsync(samjs.options.config)["catch"](function() {
              return "{}";
            }).then(JSON.parse)["catch"](function() {
              return {};
            }).then(function(data) {
              data[_this.name] = newContent;
              _this.data = newContent;
              return fs.writeFileAsync(samjs.options.config, JSON.stringify(data));
            });
          };
        })(this)).then((function(_this) {
          return function() {
            samjs.emit(_this.name + ".updated", newContent);
            return newContent;
          };
        })(this));
      };

      return Config;

    })();
    return samjs.configs = function() {
      var config, configs, createConfig, def, defaults, gets, i, j, k, len, len1, len2, mutators, plugin, reader, ref, sets, tests;
      configs = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      samjs.helper.inOrder("configs");
      configs = samjs.helper.parseSplats(configs);
      samjs.debug.configs("emitting 'beforeConfigs'");
      samjs.emit("beforeConfigs", configs);
      samjs.debug.configs("processing");
      mutators = [];
      defaults = [];
      gets = [];
      sets = [];
      tests = [];
      ref = samjs._plugins;
      for (i = 0, len = ref.length; i < len; i++) {
        plugin = ref[i];
        if (plugin.configs != null) {
          plugin.debug("got configs");
          if (plugin.configs.defaults != null) {
            if (samjs.util.isFunction(plugin.configs.defaults)) {
              defaults = defaults.concat(plugin.configs.defaults(samjs));
            } else {
              defaults = defaults.concat(plugin.configs.defaults);
            }
          }
          if (plugin.configs.mutator != null) {
            mutators.push(plugin.configs.mutator);
          }
          if (plugin.configs.test != null) {
            tests.push(plugin.configs.test);
          }
          if (plugin.configs.get != null) {
            gets.push(plugin.configs.get);
          }
          if (plugin.configs.set != null) {
            sets.push(plugin.configs.set);
          }
        }
      }
      reader = fs.readFileAsync(samjs.options.config).then(JSON.parse)["catch"](samjs.debug.configs);
      createConfig = function(options) {
        var config, j, len1, mutator;
        for (j = 0, len1 = mutators.length; j < len1; j++) {
          mutator = mutators[j];
          options = mutator(options);
        }
        config = new Config(options);
        config.load(reader)["catch"](function() {});
        config.set = (function(data, client) {
          var e, k, len2, setter;
          if (!this.write) {
            return samjs.Promise.reject(new Error("no permission"));
          }
          for (k = 0, len2 = sets.length; k < len2; k++) {
            setter = sets[k];
            try {
              data = setter.bind(this)(data, client);
            } catch (_error) {
              e = _error;
              return samjs.Promise.reject(e);
            }
          }
          return this._set(data);
        }).bind(config);
        config.test = (function(data, client) {
          var e, k, len2, tester;
          if (!this.write) {
            return samjs.Promise.reject(new Error("no permission"));
          }
          for (k = 0, len2 = tests.length; k < len2; k++) {
            tester = tests[k];
            try {
              data = tester.bind(this)(data, client);
            } catch (_error) {
              e = _error;
              return samjs.Promise.reject(e);
            }
          }
          return this._test(data);
        }).bind(config);
        config.get = (function(client) {
          var e, getter, k, len2;
          if (!this.read) {
            return samjs.Promise.reject(new Error("no permission"));
          }
          for (k = 0, len2 = gets.length; k < len2; k++) {
            getter = gets[k];
            try {
              getter.bind(this)(client);
            } catch (_error) {
              e = _error;
              return samjs.Promise.reject(e);
            }
          }
          return this._get();
        }).bind(config);
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
      samjs.debug.configs("emitting 'configs'");
      samjs.emit("configs", configs);
      samjs.debug.configs("finished");
      samjs.expose.models();
      return samjs;
    };
  };

}).call(this);
