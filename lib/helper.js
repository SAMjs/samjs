(function() {
  var randomBytes,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    slice = [].slice;

  randomBytes = require("crypto").randomBytes;

  module.exports = function(samjs) {
    var Helper, util;
    util = samjs.util;
    return samjs.helper = new (Helper = (function() {
      function Helper() {
        this.clone = bind(this.clone, this);
        this.merge = bind(this.merge, this);
      }

      Helper.prototype.generateToken = function(size) {
        return new samjs.Promise(function(resolve, reject) {
          try {
            return resolve(randomBytes(size).toString("base64"));
          } catch (error) {
            return reject();
          }
        });
      };

      Helper.prototype.merge = function(arg1) {
        var clone, dest, j, k, len, overwrite, ref, src, tmp, v;
        dest = arg1.dest, src = arg1.src, overwrite = arg1.overwrite, clone = arg1.clone;
        if ((src != null) && samjs.util.isObject(src)) {
          if (overwrite == null) {
            overwrite = false;
          }
          if (clone == null) {
            clone = false;
          }
          ref = Object.getOwnPropertyNames(src);
          for (j = 0, len = ref.length; j < len; j++) {
            k = ref[j];
            v = src[k];
            if (samjs.util.isArray(v)) {
              if ((dest[k] != null) && !overwrite) {
                tmp = this.clone(v).filter(function(item) {
                  return dest[k].indexOf(item) < 0;
                });
                dest[k] = dest[k].concat(tmp);
              } else if (clone) {
                dest[k] = this.clone(v);
              } else {
                dest[k] = v;
              }
            } else if (samjs.util.isObject(v)) {
              if (dest[k] != null) {
                dest[k] = this.merge({
                  dest: dest[k],
                  src: v,
                  overwrite: overwrite,
                  clone: clone
                });
              } else {
                if (clone) {
                  dest[k] = this.clone(v);
                } else {
                  dest[k] = v;
                }
              }
            } else if (samjs.util.isFunction(v)) {
              if (dest[k] == null) {
                dest[k] = v.bind(dest);
              }
            } else {
              if (overwrite || (dest[k] == null)) {
                dest[k] = v;
              }
            }
          }
        }
        return dest;
      };

      Helper.prototype.clone = function(obj) {
        var item, j, len, result;
        if (samjs.util.isArray(obj)) {
          result = [];
          for (j = 0, len = obj.length; j < len; j++) {
            item = obj[j];
            result.push(this.clone(item));
          }
          return result;
        } else if (samjs.util.isObject(obj)) {
          return this.merge({
            dest: {},
            src: obj,
            overwrite: true,
            clone: true
          });
        } else {
          return obj;
        }
      };

      Helper.prototype.inOrder = function(origin) {
        var i;
        i = samjs.order.indexOf(origin);
        if (i < samjs.order.length - 1 && (samjs[samjs.order[i + 1]] != null)) {
          throw new Error(origin + " already called");
        }
      };

      Helper.prototype.parseSplats = function(obj) {
        if (obj != null) {
          if (util.isArray(obj) && obj.length === 1 && util.isArray(obj[0])) {
            return obj[0];
          }
          return obj;
        }
        return [];
      };

      Helper.prototype.initiateHooks = function(obj, asyncHooks, syncHooks) {
        obj._hooks = {};
        obj.addHook = function(name, hook, after) {
          var add, j, len, removers, singleHook;
          if (obj._hooks[name] != null) {
            if (after == null) {
              after = name.indexOf("after") > -1;
            }
            add = function(hook) {
              var hooks;
              hooks = obj._hooks[name]._hooks;
              if (samjs.util.isFunction(hook)) {
                if (after) {
                  hooks.push(hook);
                } else {
                  hooks.unshift(hook);
                }
              }
              return function() {
                var i;
                i = hooks.indexOf(hook);
                if (i > -1) {
                  return hooks.splice(i, 1);
                }
              };
            };
            removers = [];
            if (samjs.util.isArray(hook)) {
              for (j = 0, len = hook.length; j < len; j++) {
                singleHook = hook[j];
                removers.push(add(singleHook));
              }
            } else {
              removers.push(add(hook));
            }
            return function() {
              var l, len1, remover, results;
              results = [];
              for (l = 0, len1 = removers.length; l < len1; l++) {
                remover = removers[l];
                results.push(remover());
              }
              return results;
            };
          } else {
            throw new Error("invalid hook name:" + name);
          }
        };
        syncHooks.forEach(function(hookname) {
          obj._hooks[hookname] = function(arg) {
            var hook, j, len, ref;
            ref = obj._hooks[hookname]._hooks;
            for (j = 0, len = ref.length; j < len; j++) {
              hook = ref[j];
              arg = hook.bind(obj)(arg);
            }
            return arg;
          };
          return obj._hooks[hookname]._hooks = [];
        });
        return asyncHooks.forEach(function(hookname) {
          obj._hooks[hookname] = function() {
            var args, hook, j, len, promise, ref;
            args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
            promise = samjs.Promise.resolve.apply(null, args);
            ref = obj._hooks[hookname]._hooks;
            for (j = 0, len = ref.length; j < len; j++) {
              hook = ref[j];
              promise = promise.then(hook.bind(obj));
            }
            return promise;
          };
          return obj._hooks[hookname]._hooks = [];
        });
      };

      Helper.prototype.addHook = function(obj, name, hook) {
        if (samjs.util.isArray(obj[name])) {
          return obj[name].push(hook);
        } else if (samjs.util.isFunction(obj[name])) {
          return obj[name] = [obj[name], hook];
        } else {
          return obj[name] = [hook];
        }
      };

      return Helper;

    })());
  };

}).call(this);
