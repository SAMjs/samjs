chai = require "chai"
should = chai.should()
samjs = require "../src/main"
someKey = "someKey"
someValue = "someValue"

describe "samjs", ->
  describe "options", ->
    describe "properties", ->
      before ->
        samjs.reset().then (samjs) ->
          samjs.plugins().options()
      it "should have defaults", ->
        samjs.options.config.should.equal("config.json")
      it "should be changeable", ->
        samjs.options.config = someValue
        samjs.options.config.should.equal(someValue)
      it "should be resetable", ->
        samjs.options.config = someValue
        samjs.reset().then (samjs) ->
          samjs.plugins().options()
          samjs.options.config.should.equal("config.json")

    describe "function call", ->
      beforeEach ->
        samjs.reset().then (samjs) ->
          samjs.plugins()
      it "should make changes", ->
        samjs.options({config:someValue})
        samjs.options.config.should.equal(someValue)
      it "should return samjs" , ->
        samjs.options().should.equal(samjs)
    describe "plugin interaction", ->
      beforeEach ->
        samjs.reset()
      it "should take plugin defaults",->
        samjs.plugins(options: someKey:someValue).options()
        should.exist samjs.options[someKey]
        samjs.options[someKey].should.equal someValue
      it "should  overwrite previous defaults",->
        samjs.plugins(options: config:someValue).options()
        samjs.options.config.should.equal someValue
