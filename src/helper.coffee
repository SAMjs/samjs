# out: ../lib/helper.js
module.exports = (samjs) ->
  util = samjs.util
  samjs.helper = new class Helper
    merge: ({dest, src, overwrite, clone}) =>
      if src? and samjs.util.isObject(src)
        overwrite ?= false
        clone ?= false
        for k,v of src
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
