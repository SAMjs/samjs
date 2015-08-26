chai = require "chai"
should = chai.should()
samjs = require "../src/main"
Promise = samjs.Promise
fs = Promise.promisifyAll(require("fs"))
custom = "custom"
testConfigFile = "test/testConfig.json"

describe "samjs", ->

  before (done) ->
    fs.unlinkAsync testConfigFile
    .catch -> return true
    .finally ->
      done()
  describe "configs", ->
    describe "a config item",->
      beforeEach -> samjs.reset().plugins().options({config:testConfigFile})
      it "should be createable", ->
        samjs.configs({name:"test"})
        samjs.configs["test"].should.be.a("object")
        samjs.configs["test"].class.should.equal("Config")
      it "should reject _getBare", (done) ->
        samjs.configs({name:"_getBare"})
        config = samjs.configs["_getBare"]
        getter = config._getBare()
        getter.then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "config _getBare not set"
          getter.should.equal(config.loaded)
        .catch done
        .then -> getter = config._getBare()
        .then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "config _getBare not set"
          getter.should.not.equal(config.loaded)
          done()
        .catch done
      it "should be _setable and _getable", (done) ->
        samjs.configs({name:"test"})
        config = samjs.configs["test"]
        config._set("testData")
        .then config._get
        .then (result) ->
          result.should.equal("testData")
          done()
        .catch done
      it "should be _testable", (done) ->
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
          done()
        .catch done
      it "should be setable", (done) ->
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
          done()
        .catch done
      it "should be getable", (done) ->
        samjs.configs({name:"test",read:true})
        config = samjs.configs["test"]
        config._set("testData")
        .then config.get
        .then (result) ->
          result.should.equal("testData")
          return config.set("testData2")
        .then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "no permission"
          done()
        .catch done
      it "should be testable", (done) ->
        samjs.configs({name:"test",write:false, test: ((data) ->
          if data == custom
            return Promise.resolve(data)
          else
            return Promise.reject(data)
        )})
        samjs.configs["test"].test(custom)
        .then (msg) ->
          should.not.exist msg
        .catch (e) ->
          e.message.should.equal "no permission"
          samjs.configs["test"].write = true
          return samjs.configs["test"].test(custom)
        .then (msg) ->
          msg.should.equal(custom)
          return samjs.configs["test"].test(false)
        .then (msg) ->
          should.not.exist msg
        .catch (msg) ->
          msg.should.be.false
          done()
        .catch done
      it "should save properly with custom config file", (done) ->
        samjs.configs({name:"test"})
        samjs.configs.test._set custom
        .then () ->
          return fs.readFileAsync testConfigFile
            .then JSON.parse
            .then (content) ->
              content.test.should.equal custom
              done()
        .catch done
    describe "plugin interaction", ->
      beforeEach ->
        samjs.reset()
      start = (plugins) ->
        samjs.plugins(plugins).options({config:testConfigFile})
      it "should take plugin defaults",->
        start(configs: defaults: [{name:"test"},{name:"test2",isRequired:true}])
        .configs({name:"test2",isRequired:false})
        should.exist samjs.configs["test"]
        samjs.configs["test"].should.be.a("object")
        samjs.configs["test"].class.should.equal("Config")
        should.exist samjs.configs["test2"]
        samjs.configs["test2"].should.be.a("object")
        samjs.configs["test2"].class.should.equal("Config")
        samjs.configs["test2"].isRequired.should.be.false
      it "should take plugin mutator",->
        start({configs: {mutator: (options) ->
          options.isRequired = true
          return options
        }}).configs({name:"test"},{name:"test2",isRequired:false})
        samjs.configs["test"].isRequired.should.be.true
        samjs.configs["test2"].isRequired.should.be.true
      it "should take plugin getter", (done) ->
        start({configs: {get: (val) ->
          if val != true
            throw new Error "not true"
        }}).configs({name:"getter",read:true})
        samjs.configs["getter"].get(true)
          .then (result) ->
            should.not.exist(result)
          .catch done
          .then ->
            samjs.configs["getter"].get(false)
          .catch (e) ->
            e.message.should.equal "not true"
            done()
      it "should take plugin setter", (done) ->
        start({configs: {set: (val, data) ->
          if val != true
            throw new Error "not true"
          return data
        }}).configs({name:"setter",write:true})
        samjs.configs["setter"].set(true,"value")
          .then ->
            samjs.configs["setter"]._get()
          .then (result) ->
            result.should.equal "value"
          .catch done
          .then ->
            samjs.configs["setter"].set(false)
          .catch (e) ->
            e.message.should.equal "not true"
            done()
      it "should take plugin tester", (done) ->
        start({configs: {test: (val,data) ->
          if val != true
            throw new Error "not true"
          return data
        }}).configs({name:"tester",write:true})
        samjs.configs["tester"].test(true, "value")
          .then (result) ->
            result.should.equal "value"
          .catch done
          .then ->
            samjs.configs["tester"].test(false)
          .catch (e) ->
            e.message.should.equal "not true"
            done()
