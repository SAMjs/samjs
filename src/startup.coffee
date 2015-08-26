# out: ../lib/startup.js
io = require "socket.io"
module.exports = (samjs) -> samjs.startup = (server) ->
  throw new Error "already started up, shutdown first" if samjs.started?
  samjs.debug.startup("emitting 'beforeStartup'")
  samjs.emit "beforeStartup", server
  samjs.debug.startup "processing"
  if server
    samjs.debug.startup "got server"
    samjs.io = io(server)
  else
    samjs.debug.startup "creating httpServer"
    samjs.io = io()
  samjs.debug.startup "checking installation"
  install = require("./install")(samjs)
  samjs.started = samjs.state.ifConfigured()
  .then -> samjs.debug.startup "already configured"
  .catch install.configure
  .then ->
    samjs.debug.startup "starting plugins"
    required = []
    for plugin in samjs._plugins
      if plugin.startup? and samjs.util.isFunction plugin.startup
        required.push plugin.startup()
    samjs.Promise.all required
  .then -> samjs.debug.startup "plugins started"
  .then ->
    samjs.debug.startup "starting models"
    required = []
    for name, model of samjs.models
      required.push model.startup?.bind(model)()
    samjs.Promise.all required
  .then -> samjs.debug.startup "models started"
  .then samjs.state.ifInstalled
  .then -> samjs.debug.startup "already installed"
  .catch install.install
  .then install.finish
  .then ->
    samjs.debug.startup "exposing configuration"
    samjs.io.of("/config").on "connection", require("./configsInterface")(samjs)
  .then ->
    samjs.debug.startup "exposing models"
    for name, model of samjs.models
      for name, listener of model.interfaces
        samjs.io.of("/#{name}").on "connection", listener.bind(model)
  .then ->
    samjs.debug.startup("emitting 'startup'")
    samjs.emit "startup"
    samjs.debug.startup("finished")
    samjs.io.of("/").emit "loaded"
    samjs.expose.shutdown()
    return samjs
  return samjs
