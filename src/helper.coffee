# out: ../lib/helper.js
module.exports = (samjs) ->
  util = samjs.util
  samjs.helper = new class Helper
    merge: ({dest, src, overwrite, clone}) =>
      if src? and samjs.util.isObject(src)
        overwrite ?= false
        clone ?= false
        for k in Object.getOwnPropertyNames(src)
          v = src[k]
          if samjs.util.isArray(v)
            if dest[k]? and not overwrite
              tmp = @clone(v).filter (item) -> dest[k].indexOf(item) < 0
              dest[k] = dest[k].concat tmp
            else if clone
              dest[k] = @clone(v)
            else
              dest[k] = v
          else if samjs.util.isObject(v)
            if dest[k]?
              dest[k] = @merge(
                dest: dest[k]
                src: v
                overwrite: overwrite
                clone:clone
                )
            else
              if clone
                dest[k] = @clone v
              else
                dest[k] = v
          else if samjs.util.isFunction(v)
            unless dest[k]?
              dest[k] = v.bind(dest)
          else
            if overwrite or not dest[k]?
              dest[k] = v
      return dest
    clone: (obj) =>
      if samjs.util.isArray(obj)
        result = []
        for item in obj
          result.push @clone(item)
        return result
      else if samjs.util.isObject(obj)
        @merge dest:{},src:obj,overwrite:true,clone:true
      else
        return obj
    inOrder: (origin) ->
      i = samjs.order.indexOf origin
      if i < samjs.order.length-1 and samjs[samjs.order[i+1]]?
        throw new Error "#{origin} already called"
    parseSplats: (obj) ->
      if obj?
        if util.isArray(obj) and obj.length == 1 and util.isArray(obj[0])
          return obj[0]
        return obj
      return []
    initiateHooks: (obj,asyncHooks,syncHooks) ->
      obj._hooks = {}
      obj.addHook = (name, hook, after) ->
        if obj._hooks[name]?
          after ?= name.indexOf("after") > -1
          add = (hook) ->
            hooks = obj._hooks[name]._hooks
            if samjs.util.isFunction(hook)
              if after
                hooks.push(hook)
              else
                hooks.unshift(hook)
            return ->
              i = hooks.indexOf(hook)
              hooks.splice(i,1) if i > -1
          removers = []
          if samjs.util.isArray(hook)
            removers.push(add(singleHook)) for singleHook in hook
          else
            removers.push(add(hook))
          return ->
            remover() for remover in removers
        else
          throw new Error("invalid hook name:#{name}")
      syncHooks.forEach (hookname) ->
        obj._hooks[hookname] = (arg) ->
          for hook in obj._hooks[hookname]._hooks
            arg = hook.bind(obj)(arg)
          return arg
        obj._hooks[hookname]._hooks = []
      asyncHooks.forEach (hookname) ->
        obj._hooks[hookname] = (args...) ->
          promise = samjs.Promise.resolve.apply(null,args)
          for hook in obj._hooks[hookname]._hooks
            promise = promise.then hook.bind(obj)
          return promise
        obj._hooks[hookname]._hooks = []
    addHook: (obj,name,hook) ->
      if samjs.util.isArray(obj[name])
        obj[name].push hook
      else if samjs.util.isFunction(obj[name])
        obj[name] = [obj[name],hook]
      else
        obj[name] = [hook]
