(function() {
  var connections;

  connections = [];

  module.exports = function(samjs) {
    return function(options, cb) {
      var io, listen, reload;
      io = null;
      listen = function() {
        var server;
        server = samjs.io.httpServer;
        if (server == null) {
          server = samjs.io;
        }
        return server.listen(options.port, options.host, function() {
          var str;
          if (options.host) {
            str = "http://" + options.host + ":" + options.port + "/";
          } else {
            str = "port: " + options.port;
          }
          return console.log("samjs server listening on " + str);
        });
      };
      if (cb == null) {
        cb = options;
        options = {};
      }
      options = Object.assign({
        port: 8080,
        dev: process.env.NODE_ENV !== "production"
      }, options);
      samjs.debug.bootstrap("calling initial bootstrap");
      cb(samjs);
      samjs.state.onceStarted.then(function() {
        samjs.debug.bootstrap("starting server");
        listen();
        if (options.dev) {
          io = samjs.io;
          return samjs.io.httpServer.on("connection", function(con) {
            connections.push(con);
            return con.on("close", function() {
              return connections.splice(connections.indexOf(con), 1);
            });
          });
        }
      });
      if (options.dev) {
        reload = function(resolve, reject) {
          var e;
          samjs.debug.bootstrap("resetting samjs");
          samjs.reset();
          samjs.io = io;
          try {
            cb(samjs);
            resolve(samjs);
          } catch (error) {
            e = error;
            reject(e);
          }
          return samjs.state.onceStarted.then(listen);
        };
        samjs.reload = function() {
          var i, len, plugin, ref, ref1, shutdowns;
          shutdowns = [];
          if (samjs._plugins != null) {
            samjs.debug.core("shuting down all plugins");
            ref = samjs._plugins;
            for (i = 0, len = ref.length; i < len; i++) {
              plugin = ref[i];
              shutdowns.push((ref1 = plugin.shutdown) != null ? ref1.bind(samjs)() : void 0);
            }
          }
          return samjs.Promise.all(shutdowns).then(function() {
            return samjs._plugins = null;
          }).then(function() {
            return new samjs.Promise(function(resolve, reject) {
              var con, j, len1, ref2;
              samjs.debug.bootstrap("initiating reload");
              if (((ref2 = samjs.io) != null ? ref2.httpServer : void 0) != null) {
                samjs.debug.bootstrap("closing server");
                samjs.io.httpServer.once("close", reload.bind(null, resolve, reject));
                for (j = 0, len1 = connections.length; j < len1; j++) {
                  con = connections[j];
                  con.destroy();
                }
                samjs.io.httpServer.close();
                samjs.io.engine.close();
                return samjs.io.close();
              } else {
                samjs.debug.bootstrap("no server found");
                return reload(resolve, reject);
              }
            });
          });
        };
      }
      return samjs;
    };
  };

}).call(this);
