chai = require "chai"
should = chai.should()
samjs = require "../src/main"

describe "samjs", ->
  describe "at start", ->
    it "should expose plugins and helper", ->
      samjs.plugins.should.be.a("function")
      samjs.helper.should.be.a("object")
    it "should not expose other functions", ->
      for prop in samjs.props
        should.not.exist(samjs[prop])
  describe "after setting plugins", ->
    before ->
      samjs.reset().then (samjs) -> samjs.plugins()
    it "should expose options", ->
      samjs.options.should.be.a("function")
    it "should throw when calling plugins", ->
      samjs.plugins.should.throw()
    describe "after setting options", ->
      before ->
        samjs.options()
      it "should expose configs", ->
        samjs.configs.should.be.a("function")
      it "should throw when calling plugins or options", ->
        samjs.options.should.throw()
        samjs.plugins.should.throw()
      describe "after setting configs", ->
        before ->
          samjs.configs()
        it "should expose models", ->
          samjs.models.should.be.a("function")
        it "should throw when calling plugins, options or configs", ->
          samjs.configs.should.throw()
          samjs.options.should.throw()
          samjs.plugins.should.throw()
        describe "after setting models", ->
          before ->
            samjs.models()
          it "should expose startup", ->
            samjs.startup.should.be.a("function")
          it "should throw when calling plugins, options, configs or models", ->
            samjs.models.should.throw()
            samjs.configs.should.throw()
            samjs.options.should.throw()
            samjs.plugins.should.throw()

  it "should be chainable", ->
    samjs.reset().then (samjs) ->
      samjs.plugins().options.should.be.a("function")
      samjs.options().configs.should.be.a("function")
      samjs.configs().models.should.be.a("function")
      samjs.models().startup.should.be.a("function")

  it "should be a singleton", ->
    samjs.reset().then (samjs) ->
      samjs.plugins().options().configs()
      samjs.models.should.equal(require("../src/main").models)

  it "should be blank after reset", ->
    samjs.reset().then (samjs) ->
      for prop in samjs.props
        should.not.exist(samjs[prop])
