(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = function(samjs) {
    var Lifecycle, State, asyncStateNames, i, len, lifecycleNames, prop, ref, stateNames;
    stateNames = ["configure", "configured", "install", "installed", "started"];
    asyncStateNames = ["beforeExposing"];
    lifecycleNames = ["reset", "beforeConfigure", "beforeInstall"].concat(stateNames);
    ref = samjs.order;
    for (i = 0, len = ref.length; i < len; i++) {
      prop = ref[i];
      lifecycleNames.push(prop);
      lifecycleNames.push("before" + prop.charAt(0).toUpperCase() + prop.slice(1));
    }
    samjs.helper.initiateHooks(samjs, asyncStateNames, lifecycleNames);
    lifecycleNames = lifecycleNames.concat(asyncStateNames);
    samjs.lifecycle = new (Lifecycle = (function() {
      function Lifecycle() {
        lifecycleNames.forEach((function(_this) {
          return function(name) {
            return _this[name] = function(obj) {
              samjs.debug.lifecycle(name);
              samjs.emit(name, obj);
              return samjs._hooks[name](obj);
            };
          };
        })(this));
      }

      return Lifecycle;

    })());
    return samjs.state = new (State = (function() {
      function State() {
        this.checkInstalled = bind(this.checkInstalled, this);
        this.reset = bind(this.reset, this);
        this.init();
      }

      State.prototype.init = function() {
        var j, len1, name;
        for (j = 0, len1 = stateNames.length; j < len1; j++) {
          prop = stateNames[j];
          name = "once" + prop.charAt(0).toUpperCase() + prop.slice(1);
          this[name] = new samjs.Promise(function(resolve) {
            return samjs.once(prop, resolve);
          });
        }
        return this.onceConfigureOrInstall = new samjs.Promise(function(resolve) {
          var resolveAndCleanup;
          resolveAndCleanup = function() {
            resolve();
            samjs.removeListener("configure", resolveAndCleanup);
            return samjs.removeListener("install", resolveAndCleanup);
          };
          samjs.once("configure", resolveAndCleanup);
          return samjs.once("install", resolveAndCleanup);
        });
      };

      State.prototype.reset = function() {
        return this.init();
      };

      State.prototype.ifConfigured = function(exclude) {
        return samjs.configs.isConfigured._get().then(function(isConfigured) {
          var k, ref1, required, v;
          if (isConfigured) {
            return;
          }
          required = [];
          ref1 = samjs.configs;
          for (k in ref1) {
            v = ref1[k];
            if ((v != null) && v.isRequired && (v._test != null) && v.name !== exclude) {
              required.push(v._getBare().then(v._test));
            }
          }
          return samjs.Promise.all(required).then(function() {
            return samjs.configs.isConfigured._set(true);
          })["catch"](function(e) {
            throw new Error("not configured");
          });
        });
      };

      State.prototype.ifInstalled = function() {
        return samjs.configs.isInstalled._get().then(function(isInstalled) {
          var k, ref1, required, v;
          if (isInstalled) {
            return;
          }
          required = [];
          ref1 = samjs.models;
          for (k in ref1) {
            v = ref1[k];
            if (((v != null ? v.isRequired : void 0) != null) && v.isRequired && (v.test != null)) {
              required.push(v.test.bind(v)());
            }
          }
          return samjs.Promise.all(required).then(function() {
            return samjs.configs.isInstalled._set(true);
          })["catch"](function(e) {
            throw new Error("not installed");
          });
        });
      };

      State.prototype.checkInstalled = function() {
        return this.ifInstalled().then(function() {
          return samjs.lifecycle.installed();
        })["catch"](function() {
          return true;
        });
      };

      return State;

    })());
  };

}).call(this);