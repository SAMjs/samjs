# out: ../lib/bootstrap.js
connections = []
module.exports = (samjs) -> (options, cb) ->
  io = null
  busy = false
  callCb = ->
    if options.server
      samjs.server = options.server
    if samjs.util.isString(cb)
      require(cb)(samjs)
    else
      cb(samjs)
    busy = true
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
  samjs.debug.bootstrap "calling initial bootstrap"
  if options.dev
    chokidar = require "chokidar"
    uncache = require "recursive-uncache"
    unwatchedModules = []
    watcher = null
    for k,v of require.cache
      unwatchedModules.push k
  callCb()
  samjs.state.onceStarted.then ->
    samjs.debug.bootstrap "starting server"
    listen()
    if options.dev 
      filesToWatch = []
      for k,v of require.cache
        if unwatchedModules.indexOf(k) < 0
          filesToWatch.push k
      unless watcher?
        watcher = chokidar.watch filesToWatch, ignoreInitial: true
        .on "all", (e,filepath) => 
          return if busy
          uncache(filepath)
          samjs.reload()
      else
        watcher.add filesToWatch
      # track server
      samjs.io.httpServer.on "connection", (con) ->
        connections.push con
        con.on "close", ->
          connections.splice(connections.indexOf(con),1)

  if options.dev # add reload
    reload = (resolve, reject) ->
      samjs.debug.bootstrap "resetting samjs"
      samjs.reset().then ->
        try
          callCb(samjs)
          resolve(samjs)
        catch e
          reject(e)
        samjs.state.onceStarted.then listen
    samjs.reload = ->
      return if busy
      busy = true
      shutdowns = []
      if samjs._plugins?
        samjs.debug.core "shuting down all plugins"
        for plugin in samjs._plugins
          shutdowns.push plugin.shutdown?.bind(samjs)()
      samjs.Promise.all(shutdowns)
      .then -> samjs._plugins = null
      .then -> new samjs.Promise (resolve, reject) ->
        samjs.debug.bootstrap "initiating reload"
        if samjs.io?.httpServer?
          samjs.debug.bootstrap "closing server"
          samjs.io.httpServer.once "close", reload.bind(null,resolve, reject)
          for con in connections
            con.destroy()
          samjs.io.httpServer.close()
          samjs.io.engine.close()
          samjs.io.close()
        else
          samjs.debug.bootstrap "no server found"
          reload(resolve, reject)
  return samjs
