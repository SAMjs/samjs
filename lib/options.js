(function() {
  module.exports = function(samjs) {
    return samjs.options = function(options) {
      var defaults, i, len, plugin, ref;
      samjs.helper.inOrder("options");
      samjs.lifecycle.beforeOptions(options);
      samjs.debug.options("processing");
      if (options != null) {
        samjs.options = samjs.helper.merge({
          dest: samjs.options,
          src: options,
          overwrite: true
        });
      }
      defaults = [
        {
          config: "config.json"
        }
      ];
      ref = samjs._plugins;
      for (i = 0, len = ref.length; i < len; i++) {
        plugin = ref[i];
        if (plugin.options != null) {
          plugin.debug("got default options");
          defaults.unshift(plugin.options);
        }
      }
      samjs.options.setDefaults = function(overwrite) {
        var def, j, len1, results;
        if (overwrite == null) {
          overwrite = true;
        }
        results = [];
        for (j = 0, len1 = defaults.length; j < len1; j++) {
          def = defaults[j];
          results.push(samjs.options = samjs.helper.merge({
            dest: samjs.options,
            src: def,
            overwrite: overwrite
          }));
        }
        return results;
      };
      samjs.options.setDefaults(false);
      samjs.lifecycle.options(options);
      samjs.debug.options("finished");
      samjs.expose.configs();
      return samjs;
    };
  };

}).call(this);
