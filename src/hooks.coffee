{isFunction} = require "core-util-is"
{arrayize} = require "./_helper"

addHook = (arr, o) =>
  if isFunction(o)
    o = hook: o, prio: 0
  unless o?.hook? and o.prio?
    throw new Error "a hook needs a 'hook' and a 'prio' property"
  arr.push o
getExec = (obj, arr) =>
  arr = arr.slice()
    .sort (a, b) => a = a.prio; b = b.prio; ((a < b) - (b < a)) 
    .map (tmp) => tmp.hook.bind(obj)
  return (o) =>
    for hook in arr
      await hook(o)
callHook = (object, prop, obj, arr, o) => await (object[prop] ?= getExec(obj, arr))(o)
getHook = (object, prop, obj) =>
  arr = object[prop]
  result = callHook.bind(null, object, prop+"Exec", obj, arr)
  result.call = addHook.bind(null, arr)
  return result
getter = (hooks, prop, obj, target, name) =>
  if target[name]?
    return target[name]
  else if (tmp = hooks[name])?
    return target[name] = getHook(tmp, prop, obj)
  else
    throw new Error "no hook '#{prop}.#{name}' registered"
hookup = (obj, prefix) =>
  prefix ?= ["before","after"]
  hooks = {}
  for prop in prefix
    obj[prop] = new Proxy {}, get: getter.bind(null, hooks, prop, obj)
  tmp = obj.hooks ?= {}
  getEmpty = (name) => prefix.reduce ((current, prefix) => 
    arr = current[prefix] = []
    if (toAdd = tmp[name]?[prefix])?
      for o in arrayize(toAdd)
        addHook(arr, o)
    return current
    ),{}
  tmp._hooks = hooks
  tmp.register = (names) =>
    for name in arrayize(names)
      h = hooks[name] ?= getEmpty(name)
  

module.exports = 
  hookup: hookup
  tests: (should) ->
    it "should register", (done) =>
      @hooks.register "test"
      samjs = @
      @before.test.call ->
        @should.equal samjs
        done()
      @before.test()
    it "should throw when not registered", =>
      should.Throw (=> @before.test2()), "no hook 'before.test2' registered"
    it "should prio correctly", =>
      @hooks.register "test3"
      a = 0
      @before.test3.call prio:0, hook: => a = 1
      @before.test3.call prio:1, hook: => a = 2
      await @before.test3()
      a.should.equal 1