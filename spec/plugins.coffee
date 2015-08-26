chai = require "chai"
should = chai.should()
samjs = require "../src/main"

describe "samjs", ->
  beforeEach ->
    samjs.reset()
  describe "plugins", ->
    it "should work with splats", ->
      samjs.plugins {},{}
      samjs._plugins.length.should.equal 2
    it "should work with arrays", ->
      samjs.plugins [{},{}]
      samjs._plugins.length.should.equal 2
    it "should expose objects", ->
      samjs.plugins name:"somePlugin",obj: someKey: "someValue"
      should.exist samjs.somePlugin
      should.exist samjs.somePlugin.someKey
      samjs.somePlugin.someKey.should.equal "someValue"
    it "should create default debug", ->
      samjs.plugins {name:"somePlugin"},{}
      samjs._plugins.length.should.equal 2
      samjs._plugins[0].debug.should.be.a("function")
      samjs._plugins[1].debug.should.be.a("function")
    it "should work with function", ->
      samjs.plugins (->{})
      samjs._plugins.length.should.equal 1
    it "should expose samjs to plugins", ->
      samjs.plugins (innerSamjs) ->
        should.exist innerSamjs
        innerSamjs.should.equal.samjs
        return {}
