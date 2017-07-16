# out: ../lib/debug.js
debug = require("debug")
module.exports = expose: new Proxy {}, get: (target, name) => debug("samjs:#{name}")
