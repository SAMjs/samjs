# out: ../lib/shutdown.js
module.exports = (samjs) -> samjs.shutdown = ->
  ioClosed = new samjs.Promise (resolve) ->
    samjs.io.httpServer.on "close", ->
      samjs.debug.core("server closed")
      setTimeout resolve, 50
  samjs.io.close()
  samjs.shutdown = null
  samjs.started = null
  required = [ioClosed]
  for plugin in samjs._plugins
    if plugin.shutdown? and samjs.util.isFunction plugin.shutdown
      required.push plugin.shutdown()
  return samjs.Promise.all(required)
