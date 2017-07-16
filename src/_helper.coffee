# out: ../lib/helper.js
{randomBytes} = require "crypto"
{isObject, isArray, isFunction} = require "core-util-is"
concat = (arr1,arr2) => Array.prototype.push.apply(arr1, arr2)
merge = (dest, src, overwrite = false, shouldClone = false) =>
  if src? and isObject(src)
    for k in Object.getOwnPropertyNames(src)
      v = src[k]
      if isArray(v)
        if dest[k]? and not overwrite
          tmp = clone(v).filter (item) -> dest[k].indexOf(item) < 0
          concat dest[k], tmp
        else if shouldClone
          dest[k] = clone(v)
        else
          dest[k] = v
      else if isObject(v)
        if dest[k]?
          dest[k] = merge(dest[k], v, overwrite, shouldClone)
        else
          if shouldClone
            dest[k] = clone v
          else
            dest[k] = v
      else if isFunction(v)
        unless dest[k]?
          dest[k] = v.bind(dest)
      else
        if overwrite or not dest[k]?
          dest[k] = v
  return dest
clone = (obj) =>
  if isArray(obj)
    result = []
    for item in obj
      result.push clone(item)
    return result
  else if isObject(obj)
    merge {}, obj, true, true
  else
    return obj
module.exports = 
  generateToken: (size) => await randomBytes(size).toString("base64")
  concat: concat
  arrayize: (obj) =>
    if isArray(obj)
      return obj
    else unless obj?
      return []
    else
      return [obj]
  merge: merge
  clone: clone
  parseSplats: (obj) =>
    return [] unless obj?
    if isArray(obj) and obj.length == 1
      return tmp if isArray(tmp = obj[0])
      return [] unless tmp
    return obj
  hookInterface: (samjs, nsp, listener) =>
    samjs.after.startup.call prio: samjs.prio.HOOK_INTERFACE, hook: (io) =>
      io.of("/#{nsp}").on "connection", listener
    samjs.before.shutdown.call prio: samjs.prio.HOOK_INTERFACE, hook: (io) =>
      io.of("/#{nsp}").removeListener "connection", listener if io?
  hookTypeResponder: (model) =>
    model.after.listen.call (socket) =>
      socket.on "type", (request, cb) => cb(success: true, content: model.db)
  tests: (should) ->
    someKey = "someKey"
    someVal = "someVal"
    describe "merge", =>
      it "should work", =>
        dest = {}
        src = someKey: someVal
        result = @helper.merge dest, src
        result.should.equal dest
        dest.should.not.equal src
        should.exist dest[someKey]
        dest[someKey].should.equal someVal
      it "should merge deep", =>
        dest = {}
        src = someKey: someKey: someKey: someVal
        @helper.merge dest, src
        should.exist dest[someKey]
        should.exist dest[someKey][someKey]
        should.exist dest[someKey][someKey][someKey]
        dest[someKey][someKey][someKey].should.equal someVal
      it "should work with overwrite prop", =>
        dest = someKey: "something"
        src = someKey: someVal
        @helper.merge dest, src
        dest[someKey].should.equal "something"
        @helper.merge dest, src, false
        dest[someKey].should.equal "something"
        @helper.merge dest, src, true
        dest[someKey].should.equal someVal
    describe "clone", =>
      it "should work with objects", =>
        src = someKey:someVal
        dest = @helper.clone src
        dest.should.not.equal src
        should.exist dest[someKey]
        dest[someKey].should.equal someVal
      it "should work deep", =>
        src = someKey: someKey: someVal
        dest = @helper.clone src
        dest.should.not.equal src
        should.exist dest[someKey]
        dest[someKey].should.not.equal src[someKey]
        should.exist dest[someKey][someKey]
        dest[someKey][someKey].should.equal someVal
      it "should work with arrays", =>
        src = [someVal]
        dest = @helper.clone src
        dest.should.not.equal src
        should.exist dest[0]
        dest[0].should.equal someVal
      it "should work with deep arrays", =>
        src = [someKey:someVal]
        dest = @helper.clone src
        dest.should.not.equal src
        should.exist dest[0]
        dest[0].should.not.equal src[0]
        dest[0][someKey].should.equal someVal
    describe "parseSplats", =>
      it "should work", =>
        src = [someVal]
        dest = @helper.parseSplats src
        dest.should.equal src
        dest = @helper.parseSplats [src]
        dest.should.equal src
  

