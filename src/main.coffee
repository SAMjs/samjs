# out: ../lib/main.js
load = (name) ->
  resolved = require.resolve(name)
  if require.cache[resolved]
    delete require.cache[resolved]
  return require name
{EventEmitter} = require("events")

init = ->
  samjs = new EventEmitter()
  samjs.Promise = require "bluebird"
  samjs.socketio = require "socket.io"
  samjs.util = require "core-util-is"
  samjs.debug = require "./debug"
  samjs.order = ["plugins","options","configs","models","startup","shutdown"]
  samjs.props = ["_plugins","options","configs","models","startup", "shutdown","started"]
  samjs.state = {}
  samjs.removeAllSocketIOListeners = ->
    samjs.debug.core "remove all socketIO listeners"
    if samjs.io?
      for nid, nsp of samjs.io.nsps
        nsp.removeAllListeners()
        for id,socket of nsp.sockets
          socket.removeAllListeners()
  samjs.reset = ->
    samjs.debug.core "resetting samjs instance"
    samjs.options?.setDefaults?()
    if samjs._plugins?
      samjs.debug.core "shuting down all plugins"
      for plugin in samjs._plugins
        plugin.shutdown?.bind(samjs)()
    samjs.interfaces?.reset()
    for prop in samjs.props
      samjs[prop] = null
    samjs.removeAllSocketIOListeners()
    samjs.io = null
    samjs.lifecycle.reset()
    samjs.removeAllListeners()
    samjs.state.reset()
    samjs.expose.plugins()
    return samjs
  samjs.bootstrap = require("./bootstrap")(samjs)
  require("./helper")(samjs)
  require("./state")(samjs)
  require("./interfaces")(samjs)
  samjs.expose = {
    plugins: ->
      samjs.debug.core("exposing plugins")
      require("./plugins")(samjs)
    options: ->
      samjs.debug.core("exposing options")
      require("./options")(samjs)
    configs: ->
      samjs.debug.core("exposing config")
      load("./configs")(samjs)
    models: ->
      samjs.debug.core("exposing models")
      require("./models")(samjs)
    startup: ->
      samjs.debug.core("exposing startup")
      require("./startup")(samjs)
    shutdown: ->
      samjs.debug.core("exposing shutdown")
      require("./shutdown")(samjs)
  }
  samjs.expose.plugins()
  return samjs
module.exports = init()
