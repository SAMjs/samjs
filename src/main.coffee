# out: ../lib/main.js
load = (name) ->
  resolved = require.resolve(name)
  if require.cache[resolved]
    delete require.cache[resolved]
  return require name
{EventEmitter} = require("events")
connections = []
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
      for plugin in samjs._plugins
        plugin.shutdown?.bind(samjs)()
    samjs.interfaces?.close()
    for prop in samjs.props
      samjs[prop] = null
    samjs.removeAllSocketIOListeners()
    samjs.io = null
    samjs.lifecycle.reset()
    samjs.removeAllListeners()
    samjs.state.reset()
    samjs.expose.plugins()
    return samjs
  samjs.bootstrap = (options, cb) ->
    io = null
    listen = ->
      server = samjs.io.httpServer
      server ?= samjs.io
      server.listen options.port, options.host, ->
        if options.host
          str = "http://#{options.host}:#{options.port}/"
        else
          str = "port: #{options.port}"
        console.log "samjs server listening on #{str}"
    unless cb?
      cb = options
      options = {}
    options = Object.assign({
      port: 8080
      dev: process.env.NODE_ENV != "production"
      }, options)
    cb(samjs)
    samjs.state.onceStarted.then ->
      listen()
      if options.dev # track server
        io = samjs.io
        samjs.io.httpServer.on "connection", (con) ->
          connections.push con
          con.on "close", ->
            connections.splice(connections.indexOf(con),1)

    if options.dev # add reload
      reload = (resolve, reject) ->
        samjs.reset()
        samjs.io = io
        try
          cb(samjs)
          resolve(samjs)
        catch e
          reject(e)
        samjs.state.onceStarted.then listen
      samjs.reload = -> new samjs.Promise (resolve, reject) ->
        if samjs.io?.httpServer?
          samjs.io.httpServer.once "close", reload.bind(null,resolve, reject)
          for con in connections
            con.destroy()
          samjs.io.httpServer.close()
          samjs.io.engine.close()
          samjs.io.close()
        else
          reload(resolve)
    return samjs

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
