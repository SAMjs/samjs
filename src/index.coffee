module.exports = class Samjs
  constructor: (obj) ->
    @hookup(@)
    @init()
    if obj?
      Object.defineProperty @, "finished", get: =>
        await @setup(obj)
        await @startup(obj?.startup || null)
    return @
  prio: 
    ADD_DEFAULTS: 10000
    ADD_HOOKS: 1000
    HOOK_INTERFACE: 1000
    POST_PROCESS: -100
    PROCESS: 0
    PREPARE: 100
    ACCESS: 5000
  hookup: require("./hooks").hookup
  Promise: require "bluebird"
  socketio: require "socket.io"
  fs: require "fs-extra"
  path: require "path"
  util: require "core-util-is"
  helper: require "./_helper"
  init: ->
    for file in [
                "debug"
                "listen"
                "plugins"
                "options"
                "configs"
                "models"
                "startup"
                "shutdown"
                ]
      tmp = require("./#{file}")
      @[file] = tmp.expose
      @hooks.register tmp.hooks if tmp.hooks?
  setup: (obj = {}) ->
    for cmd in ["plugins","options","configs","models"]
      await @[cmd](obj[cmd])
