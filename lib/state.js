(function() {
  module.exports = function(samjs) {
    var State;
    return samjs.state = new (State = (function() {
      function State() {
        this.onceConfigured = new samjs.Promise((function(_this) {
          return function(resolve) {
            return samjs.once("configs", function() {
              return _this.ifConfigured().then(resolve)["catch"](function() {
                return samjs.once("configured", resolve);
              });
            });
          };
        })(this));
        this.onceInstalled = new samjs.Promise((function(_this) {
          return function(resolve) {
            return _this.onceConfigured.then(function() {
              return samjs.once("models", function() {
                return _this.ifInstalled().then(resolve)["catch"](function() {
                  return samjs.once("installed", resolve);
                });
              });
            });
          };
        })(this));
      }

      State.prototype.ifConfigured = function(exclude) {
        var k, ref, required, v;
        required = [];
        ref = samjs.configs;
        for (k in ref) {
          v = ref[k];
          if ((v != null) && v.isRequired && (v._test != null) && v.name !== exclude) {
            required.push(v._getBare().then(v._test));
          }
        }
        return samjs.Promise.all(required)["catch"](function(e) {
          throw new Error("not configured");
        });
      };

      State.prototype.ifInstalled = function() {
        var k, ref, required, v;
        required = [];
        ref = samjs.models;
        for (k in ref) {
          v = ref[k];
          if (((v != null ? v.isRequired : void 0) != null) && v.isRequired && (v.test != null)) {
            required.push(v.test.bind(v)());
          }
        }
        return samjs.Promise.all(required)["catch"](function(e) {
          throw new Error("not installed");
        });
      };

      return State;

    })());
  };

}).call(this);
