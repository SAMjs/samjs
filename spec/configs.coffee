chai = require "chai"
should = chai.should()
samjs = require "../src/main"
Promise = samjs.Promise
fs = Promise.promisifyAll(require("fs"))
custom = "custom"
testConfigFile = "test/testConfig.json"

describe "samjs", ->

  before ->
    fs.unlinkAsync testConfigFile
    .catch -> return true
  describe "configs", ->
    describe "a config item",->
      beforeEach -> samjs.reset().plugins().options({config:testConfigFile})
      it "should be createable", ->
        samjs.configs({name:"test"})
        samjs.configs["test"].should.be.a("object")
        samjs.configs["test"].class.should.equal("Config")
      it "should reject _getBare",  ->
        samjs.configs({name:"_getBare"})
        config = samjs.configs["_getBare"]
        getter = config._getBare()
        getter.then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "config _getBare not set"
          getter.should.equal(config.loaded)
        .then -> getter = config._getBare()
        .then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "config _getBare not set"
          getter.should.not.equal(config.loaded)
          return true
      it "should be _setable and _getable",  ->
        samjs.configs({name:"test"})
        config = samjs.configs["test"]
        config._set("testData")
        .then config._get
        .then (result) ->
          result.should.equal("testData")
      it "should be _testable", ->
        samjs.configs({name:"test", test: ((data) ->
          if data == custom
            return Promise.resolve(data)
          else
            return Promise.reject(data)
        )})
        samjs.configs["test"]._test(custom)
        .then (msg) ->
          msg.should.equal(custom)
          samjs.configs["test"]._test(false)
        .then (msg) ->
          should.not.exist msg
        .catch (msg) ->
          msg.should.be.false
      it "should be setable",  ->
        samjs.configs({name:"test",write:true})
        config = samjs.configs["test"]
        config.set("testData")
        .then config._get
        .then (result) ->
          result.should.equal("testData")
          return config.get()
        .then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "no permission"

      it "should be getable", ->
        samjs.configs({name:"test",read:true})
        config = samjs.configs["test"]
        config._set("testData")
        .then config.get
        .then ({data}) ->
          data.should.equal("testData")
          return config.set("testData2")
        .then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "no permission"

      it "should be testable",  ->
        samjs.configs({name:"test",access:{write:false}, test: ((data) ->
          if data == custom
            return Promise.resolve(data)
          else
            return Promise.reject(data)
        )})
        samjs.configs["test"].test(custom)
        .then ({data}) ->
          should.not.exist data
        .catch (e) ->
          e.message.should.equal "no permission"
          samjs.configs["test"].access.write = true
          return samjs.configs["test"].test(custom)
        .then ({data}) ->
          data.should.equal(custom)
          return samjs.configs["test"].test(false)
        .then ({data}) ->
          should.not.exist data
        .catch (obj) ->
          obj.should.be.false

      it "should save properly with custom config file", ->
        samjs.configs({name:"test"})
        samjs.configs.test._set custom
        .then () ->
          return fs.readFileAsync testConfigFile
            .then JSON.parse
            .then (content) ->
              content.test.should.equal custom

    describe "plugin interaction", ->
      beforeEach ->
        samjs.reset()
      start = (plugins) ->
        samjs.plugins(plugins).options({config:testConfigFile})
      it "should take plugin defaults",->
        start(configs: [{name:"test"},{name:"test2",isRequired:true}])
        .configs({name:"test2",isRequired:false})
        should.exist samjs.configs["test"]
        samjs.configs["test"].should.be.a("object")
        samjs.configs["test"].class.should.equal("Config")
        should.exist samjs.configs["test2"]
        samjs.configs["test2"].should.be.a("object")
        samjs.configs["test2"].class.should.equal("Config")
        samjs.configs["test2"].isRequired.should.be.false
      it "should take plugin beforeCreate hook",->
        start(hooks: configs: beforeCreate: [(options) ->
          options.isRequired = true
          return options
        ]).configs({name:"test"},{name:"test2",isRequired:false})
        samjs.configs["test"].isRequired.should.be.true
        samjs.configs["test2"].isRequired.should.be.true
      it "should take plugin beforeGet hook", ->
        start(hooks: configs: beforeGet: [(obj) ->
          if obj.socket != true
            throw new Error "not true"
          return obj
        ]).configs({name:"getter",access:read:true})
        samjs.configs["getter"].get(true)
          .then ({data}) ->
            should.not.exist(data)
          .catch (e) -> should.not.exist (e)
          .then ->
            samjs.configs["getter"].get(false)
          .catch (e) ->
            e.message.should.equal "not true"
      it "should take plugin beforeSet hook", ->
        start(hooks: configs: beforeSet: [(obj) ->
          if obj.socket != true
            throw new Error "not true"
          return obj
        ]).configs({name:"setter",access:write:true})
        samjs.configs["setter"].set("value", true)
          .then ->
            samjs.configs["setter"]._get()
          .then (result) ->
            result.should.equal "value"
          .catch (e) -> should.not.exist (e)
          .then ->
            samjs.configs["setter"].set("value", false)
          .catch (e) ->
            e.message.should.equal "not true"
      it "should take plugin beforeTest hook", ->
        start(hooks: configs: beforeTest: [(obj) ->
          if obj.socket != true
            throw new Error "not true"
          return obj
        ]).configs({name:"tester",access:write:true})
        samjs.configs["tester"].test("value", true)
          .then ({data}) ->
            data.should.equal "value"
          .catch (e) -> should.not.exist (e)
          .then ->
            samjs.configs["tester"].test("value", false)
          .catch (e) ->
            e.message.should.equal "not true"
