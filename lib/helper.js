(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module.exports = function(samjs) {
    var Helper, util;
    util = samjs.util;
    return samjs.helper = new (Helper = (function() {
      function Helper() {
        this.clone = bind(this.clone, this);
        this.merge = bind(this.merge, this);
      }

      Helper.prototype.merge = function(arg) {
        var clone, dest, k, overwrite, src, tmp, v;
        dest = arg.dest, src = arg.src, overwrite = arg.overwrite, clone = arg.clone;
        if ((src != null) && samjs.util.isObject(src)) {
          if (overwrite == null) {
            overwrite = false;
          }
          if (clone == null) {
            clone = false;
          }
          for (k in src) {
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

      return Helper;

    })());
  };

}).call(this);
