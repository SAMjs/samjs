(function() {
  module.exports = function(samjs) {
    var listener;
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
              content: null
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
              content: null
            };
          }).then(function(response) {
            return socket.emit(config.name + ".get." + request.token, response);
          });
        }
      });
      samjs.debug.configs("listening on " + config.name + ".set");
      return socket.on(config.name + ".set", function(request) {
        if (((request != null ? request.content : void 0) != null) && (request.token != null)) {
          return config.set(request.content, socket.client)["return"](config).call("_get").then(function(response) {
            socket.broadcast.emit("update", config.name);
            return {
              success: true,
              content: response
            };
          })["catch"](function(err) {
            return {
              success: false,
              content: null
            };
          }).then(function(response) {
            return socket.emit(config.name + ".set." + request.token, response);
          });
        }
      });
    };
    return function(socket) {
      var config, name, ref, results;
      samjs.debug.configs("socket connected");
      ref = samjs.configs;
      results = [];
      for (name in ref) {
        config = ref[name];
        results.push(listener(socket, config));
      }
      return results;
    };
  };

}).call(this);
