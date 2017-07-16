
module.exports = ({io,wrapEmit}, options) -> new class Config
  constructor: ->
    socket = @socket = io.socket("/config", options)
    @on = socket.on.bind(socket)
    emit = wrapEmit(socket)
    getter = (type, name, value) -> emit name+"."+type, value
    for type in ["test","set","get"]
      @[type] = getter.bind(null, type)
    return @
  
