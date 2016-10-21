# out: ../lib/install.js
module.exports = (samjs) ->
  debug = samjs.debug.install
  responder = (trigger,response) ->
    listener = (socket) ->
      respond = (request) ->
        if request?.token?
          debug "responding on #{trigger} with #{response}"
          socket.emit trigger+"."+request.token,
            {success:response != false, content: response}
      socket.on trigger, respond
    debug "setting #{response} responder on #{trigger}"
    samjs.io.on "connection", listener
    for socketid,socket of samjs.io.sockets.connected
      listener(socket)

  return new class Install
    configure: =>
      samjs.lifecycle.beforeConfigure()
      debug "exposing configuration"
      samjs.io.of("/configure").on "connection", (socket) =>
        debug "socket connected"
        for name,config of samjs.configs
          if config.isRequired
            @configListener socket, config
            if config.installInterface?
              config.installInterface.bind(config)(socket)


      responder("installation","configure")
      samjs.io.emit "configure"
      samjs.lifecycle.configure()
      return new samjs.Promise (resolve) ->
        samjs.state.onceConfigured.then ->
          samjs.removeAllSocketIOListeners()
          resolve()

    configListener: (socket, config) ->
      # tester
      debug "listening on #{config.name}.test"
      socket.on "#{config.name}.test", (request) ->
        if request?.content? and request.token?
          debug "testing on #{config.name}.test: #{request.content}"
          config._test(request.content)
          .then (info) -> success:true , content:info
          .catch (err) -> success:false, content:err?.message
          .then (response) ->
            socket.emit "#{config.name}.test.#{request.token}", response
      # getter
      debug "listening on #{config.name}.get"
      socket.on "#{config.name}.get", (request) ->
        if request?.token?
          debug "getting on #{config.name}.get"
          config._get()
          .then (response) -> success:true , content:response
          .catch (err)     -> success:false, content:err?.message
          .then (response) ->
            socket.emit "#{config.name}.get.#{request.token}", response
      # setter
      debug "listening on #{config.name}.set"
      socket.on "#{config.name}.set", (request) ->
        debug "setting on #{config.name}.set: #{request.content}"
        if request?.content? and request.token?
          config._set(request.content)
          .return config
          .call "_get"
          .then (response) ->
            socket.broadcast.emit "update", config.name
            samjs.state.ifConfigured(config.name)
            .then ->
              debug "config installed completely"
              samjs.lifecycle.configured()
            .catch ->
            return success:true, content:response
          .catch (err)     -> success:false, content:err?.message
          .then (response) ->
            socket.emit "#{config.name}.set.#{request.token}", response


    install: ->
      samjs.lifecycle.beforeInstall()
      debug "exposing install"
      samjs.io.of("/install").on "connection", (socket) ->
        for name, model of samjs.models
          if model.isRequired
            model.installInterface.bind(model)(socket)
      responder("installation","install")
      samjs.io.of("/configure").emit "done"
      samjs.io.emit "install"
      samjs.lifecycle.install()
      return new samjs.Promise (resolve) ->
        samjs.state.onceInstalled.then ->
          samjs.io.of("/install").emit "done"
          samjs.removeAllSocketIOListeners()
          resolve()
    finish: ->
      return new samjs.Promise (resolve) ->
        return resolve() unless samjs.io?
        responder("installation",false)
        samjs.io.of("/configure").emit "done"
        samjs.io.of("/install").emit "done"
        setTimeout (->
          if samjs.io?.engine?
            debug "issuing reconnect of all connected sockets"
            samjs.removeAllSocketIOListeners()
            samjs.io.engine.close()
          resolve()
          ),500
