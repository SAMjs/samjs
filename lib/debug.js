(function() {
  var debug, i, len, name, names, samjs;

  debug = require("debug");

  samjs = "samjs:";

  names = ["core", "bootstrap", "plugins", "lifecycle", "options", "models", "configs", "startup", "install", "shutdown"];

  module.exports = function(name) {
    return debug(samjs + name);
  };

  for (i = 0, len = names.length; i < len; i++) {
    name = names[i];
    module.exports[name] = debug(samjs + name);
  }

}).call(this);
