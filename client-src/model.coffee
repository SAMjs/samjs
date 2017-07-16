models = {}
module.exports = (samjs, options) -> (name) -> models[name] ?= new class Model
  constructor: ->
    socket = @socket = samjs.io.socket("/#{name}", options)
    @samjs = samjs
    @name = name
    @on = socket.on.bind(socket)
    @getter = samjs.wrapEmit(socket)
    @ready = new samjs.Promise (resolve) =>
      return resolve(@) if socket.id?
      socket.once "connect", =>
        return resolve(@) if samjs.plugins.length == 0
        @getter "type"
        .then (type) =>
          for plugin in samjs.plugins
            plugin.model?(@, type)
          resolve(@)
    samjs.auth.setupReconnect(socket) if samjs.auth
    return @
