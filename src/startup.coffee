# out: ../lib/startup.js

module.exports = (samjs) -> samjs.startup = (server) ->
  throw new Error "already started up, shutdown first" if samjs.started?
  samjs.server = server if server?
  samjs.lifecycle.startupInitialization()
  samjs.debug.startup "processing"
  # startup io unless it is there or said otherwise
  unless samjs.io? or samjs.noServer
    if samjs.server
      samjs.debug.startup "got server"
      samjs.io = samjs.socketio(samjs.server)
    else
      samjs.debug.startup "creating httpServer"
      samjs.io = samjs.socketio()
  samjs.state.startup = samjs.lifecycle.beforeStartup().then ->

    samjs.debug.startup "checking installation"
    install = require("./install")(samjs)
    return samjs.state.ifConfigured()
    .then ->
      samjs.lifecycle.configured()
      samjs.debug.startup "already configured"
    .catch ((e) -> e.message=="not configured"),install.configure
    .then ->
      samjs.debug.startup "starting plugins"
      required = []
      for plugin in samjs._plugins
        if plugin.startup? and samjs.util.isFunction plugin.startup
          required.push plugin.startup.bind(plugin)()
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
    .then ->
      samjs.lifecycle.installed()
      samjs.debug.startup "already installed"
    .catch ((e) -> e.message=="not installed"),install.install
    .then install.finish
    .then samjs.lifecycle.beforeExposing
    .then ->
      samjs.debug.startup "exposing interfaces"
      samjs.interfaces.expose()
    .then ->
      samjs.lifecycle.started()
      samjs.debug.startup("finished")
      samjs.io.of("/").emit "loaded"
      samjs.expose.shutdown()
      return samjs
    samjs.lifecycle.startup()
  return samjs
