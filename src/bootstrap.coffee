# out: ../lib/bootstrap.js
connections = []
module.exports = (samjs) -> (options, cb) ->
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
  samjs.debug.bootstrap "calling initial bootstrap"
  cb(samjs)
  samjs.state.onceStarted.then ->
    samjs.debug.bootstrap "starting server"
    listen()
    if options.dev # track server
      io = samjs.io
      samjs.io.httpServer.on "connection", (con) ->
        connections.push con
        con.on "close", ->
          connections.splice(connections.indexOf(con),1)

  if options.dev # add reload
    reload = (resolve, reject) ->
      samjs.debug.bootstrap "resetting samjs"
      samjs.reset()
      samjs.io = io
      try
        cb(samjs)
        resolve(samjs)
      catch e
        reject(e)
      samjs.state.onceStarted.then listen
    samjs.reload = ->
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
