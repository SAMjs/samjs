# out: ../lib/configsInterface.js
module.exports = (samjs) ->
  listener = (socket, config) ->
    # tester
    samjs.debug.configs "listening on "+ config.name + ".test"
    socket.on config.name + ".test", (request) ->
      if request?.content? and request.token?
        config.test(request.content, socket.client)
        .then (info) -> success:true , content:info
        .catch (err) -> success:false, content:null
        .then (response) ->
          socket.emit config.name + ".test." + request.token, response
    # getter
    samjs.debug.configs "listening on "+ config.name + ".get"
    socket.on config.name + ".get", (request) ->
      if request?.token?
        config.get(socket.client)
        .then (response) -> success:true , content:response
        .catch (err)     -> success:false, content:null
        .then (response) ->
          socket.emit config.name + ".get." + request.token, response
    # setter
    samjs.debug.configs "listening on "+ config.name + ".set"
    socket.on config.name + ".set", (request) ->
      if request?.content? and request.token?
        config.set(request.content, socket.client)
        .then (response) ->
          socket.broadcast.emit "updated", config.name
          success:true , content:response
        .catch (err)     -> success:false, content:null
        .then (response) ->
          socket.emit config.name + ".set." + request.token, response
  return (socket) ->
    samjs.debug.configs "socket connected"
    for name, config of samjs.configs
      listener(socket, config)
