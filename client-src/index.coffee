module.exports = class Samjs
  constructor: (o) ->
    p = @Promise = o.Promise or Promise
    @wrapEmit = (socket) -> (one, two) -> new p (resolve, reject) ->
      socket.emit one, two, (response) ->
        if response.success
          resolve response.content
        else
          reject new Error response.content
    @io = require("./io")(o.url, o.io)
    @config = require("./config")(@, o.io)
    @model = require("./model")(@, o.io)
    @plugins = o.plugins or []
    @plugins = [@plugins] unless Array.isArray(@plugins)
    for plugin in @plugins
      plugin(@, o.io)
    @finished = new @Promise (resolve) => @io.nsps["/"].once "connect", resolve
    return @
  close: -> @io.close()
