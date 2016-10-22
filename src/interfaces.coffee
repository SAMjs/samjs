# out: ../lib/interfaces.js
module.exports = (samjs) ->

  samjs.interfaces = new class Interfaces
    constructor: -> @reset()
    reset: =>
      @_interfaces =
        config: [((socket) ->
            samjs.debug.configs "socket connected"
            socket.on "disconnect", ->
              samjs.debug.configs "socket disconnected"
          )]
      @_closers = {}
    add: (name, itf) ->
      @_interfaces[name] ?= []
      @_interfaces[name].push itf

    close: (name) =>
      close = (closers) ->
        for close in closers
          close()
      if name
        if @_closers[name]?
          close(@_closers[name])
      else
        for name, closers of @_closers
          close(closers)
      return null
    expose: (name) =>
      # helper to expose a multiple (or single) interfaces
      exposeInterfaces = (interfaces, name, binding) =>
        @_closers[name] ?= []
        unless samjs.util.isArray interfaces
          interfaces = [interfaces]
        if binding?
          listener = (socket) ->
            for itf in interfaces
              itf.bind(binding)(socket)
        else
          listener = (socket) ->
            for itf in interfaces
              itf(socket)
        samjs.io.of("/#{name}").on "connection", listener
        @_closers[name].push ->
          samjs.io.of("/#{name}").removeListener "connection", listener
      # only expose a specific interface
      if name
        # a config or manual set interface
        if @_interfaces[name]?
          exposeInterfaces(@_interfaces[name], name)
        else
          # a interface connected to a model
          for modelname, model of samjs.models
            if samjs.util.isArray(model.interfaces)
              if model.name == name
                exposeInterfaces(model.interfaces,name, model)
            else if model.interfaces[name]?
              exposeInterfaces(model.interfaces[name], name, model)
          # a interface connected to a plugin
          for plugin in samjs._plugins
            if plugin.interfaces?
              if samjs.util.isArray(plugin.interfaces)
                if plugin.name == name
                  exposeInterfaces(plugin.interfaces, name, plugin)
              else if plugin.interfaces[name]?
                exposeInterfaces(plugin.interfaces[name], name, plugin)
      else
        # all config and manual set interface
        for name, interfaces of @_interfaces
          exposeInterfaces(interfaces, name)
        # all interfaces connected to all models
        for modelname, model of samjs.models
          if samjs.util.isArray(model.interfaces)
            exposeInterfaces(model.interfaces, modelname, model)
          else
            for name, interfaces of model.interfaces
              exposeInterfaces(interfaces, name, model)
        # all interfaces connected to all plugins
        for plugin in samjs._plugins
          if plugin.interfaces?
            if samjs.util.isArray(plugin.interfaces)
              exposeInterfaces(plugin.interfaces, plugin.name, plugin)
            else
              for name, interfaces of plugin.interfaces
                exposeInterfaces(interfaces, name, plugin)
      return @
