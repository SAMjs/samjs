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
    remover = ->
      debug "removing responder on #{trigger} (#{response})"
      samjs.io.of("/").removeListener "connection", listener
      for socketid,socket of samjs.io.sockets.connected
        socket.removeAllListeners trigger
    debug "setting #{response} responder on #{trigger}"
    samjs.io.on "connection", listener
    for socketid,socket of samjs.io.sockets.connected
      listener(socket)
    return remover
  return new class Install
    configure: =>
      debug "emitting beforeConfigure"
      samjs.emit "beforeConfigure"
      debug "exposing configuration"
      disposes = []
      samjs.io.of("/configure").on "connection", (socket) =>
        debug "socket connected"
        for name,config of samjs.configs
          if config.isRequired
            disposes.push @configListener socket, config
      disposes.push ->
        samjs.io.of("/configure").removeAllListeners "connection"
      deleteResponder = responder("installation","configure")
      samjs.io.emit "configure"
      debug "emitting configure"
      samjs.emit "configure"
      return new samjs.Promise (resolve) ->
        samjs.once "configured", ->
          debug "configured"
          for dispose in disposes
            dispose()
          deleteResponder()
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
              .then () ->
                debug "config installed completely"
                samjs.emit "configured"
            return success:true, content:response
          .catch (err)     -> success:false, content:err?.message
          .then (response) ->
            socket.emit "#{config.name}.set.#{request.token}", response
      return ->
        if socket?
          socket.removeAllListeners "#{config.name}.test"
          socket.removeAllListeners "#{config.name}.get"
          socket.removeAllListeners "#{config.name}.set"


    install: ->
      debug "emitting beforeInstall"
      samjs.emit "beforeInstall"
      debug "exposing install"
      disposes = []
      for name, model of samjs.models
        if model.isRequired
          samjs.io.of("/install").on "connection", (socket) ->
            disposer = model.installInterface.bind(model)(socket)
            unless samjs.util.isFunction disposer
              throw new Error "installInterface needs to return a dispose
                function model: #{name}"
            disposes.push disposer
          disposes.push ->
            samjs.io.of("/install").removeAllListeners "connection"
      deleteResponder = responder("installation","install")
      samjs.io.of("/configure").emit "done"
      samjs.io.emit "install"
      debug "emitting install"
      samjs.emit "install"
      return new samjs.Promise (resolve) ->
        samjs.on "checkInstalled", ->
          if samjs.state.ifInstalled()
            debug "emitting installed"
            samjs.emit "installed"
            for dispose in disposes
              dispose()
            deleteResponder()
            samjs.io.of("/install").emit "done"
            resolve()
    finish: ->
      responder("installation",false)
      samjs.io.of("/configure").emit "done"
      samjs.io.of("/install").emit "done"
      if samjs.io.engine?
        debug "issuing reconnect of all connected sockets"
        for socket in samjs.io.nsps["/"].sockets
          socket?.onclose("reconnect")
        samjs.io.engine.close()
