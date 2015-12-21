# out: ../lib/debug.js
debug = require("debug")
samjs = "samjs:"
names = ["core","plugins","lifecycle","options","models","configs","startup","install","shutdown"]
module.exports = (name) ->
  return debug(samjs+name)
for name in names
  module.exports[name] = debug(samjs+name)
