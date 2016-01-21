(function() {
  var slice = [].slice;

  module.exports = function(samjs) {
    return samjs.shutdown = function() {
      var i, ioClosed, len, model, name, plugin, ref, ref1, ref2, required;
      samjs.lifecycle.beforeShutdown();
      ioClosed = new samjs.Promise(function(resolve) {
        return samjs.io.httpServer.on("close", function() {
          samjs.debug.core("server closed");
          return setTimeout(resolve, 50);
        });
      });
      samjs.io.close();
      samjs.shutdown = null;
      samjs.started = null;
      required = [ioClosed];
      ref = samjs._plugins;
      for (i = 0, len = ref.length; i < len; i++) {
        plugin = ref[i];
        if ((plugin.shutdown != null) && samjs.util.isFunction(plugin.shutdown)) {
          required.push(plugin.shutdown.bind(plugin)());
        }
      }
      ref1 = samjs.models;
      for (name in ref1) {
        model = ref1[name];
        required.push((ref2 = model.shutdown) != null ? ref2.bind(model)() : void 0);
      }
      return samjs.Promise.all(required).then(function() {
        var args;
        args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        samjs.lifecycle.shutdown();
        return args;
      });
    };
  };

}).call(this);
