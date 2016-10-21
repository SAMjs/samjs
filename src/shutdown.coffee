# out: ../lib/shutdown.js
module.exports = (samjs) -> samjs.shutdown = ->
  samjs.lifecycle.beforeShutdown()
  ioClosed = new samjs.Promise (resolve) ->
    samjs.io.httpServer.once "close", ->
      samjs.debug.core("server closed")
      setTimeout resolve, 50
  samjs.io.close()
  samjs.shutdown = null
  samjs.started = null
  required = [ioClosed]
  for plugin in samjs._plugins
    if plugin.shutdown? and samjs.util.isFunction plugin.shutdown
      required.push plugin.shutdown.bind(plugin)()
  for name, model of samjs.models
    required.push model.shutdown?.bind(model)()
  return samjs.Promise.all(required).then (args...) ->
    samjs.lifecycle.shutdown()
    return args
