chai = require "chai"
should = chai.should()
samjs = require "../src/main"
reload = require "simple-reload"
fs = samjs.Promise.promisifyAll(require("fs"))

port = 3029
url = "http://localhost:"+port+"/"

testConfigFile = "test/testConfig.json"

test = (value) ->
  return new samjs.Promise (resolve,reject) ->
    if value == "rightValue"
      resolve()
    else
      reject(new Error "wrong")
describe "samjs", ->
  config = null
  before ->
    samjs.reset()
    fs.unlinkAsync testConfigFile
    .catch -> return true
  describe "configInterface", ->
    before ->
      samjs.plugins().options({config:testConfigFile}).configs({
        name: "testable"
        access:
          read: true
          write: true
        test: test
      },{
        name: "unreadable"
        access:
          write: true
      },{
        name: "unwriteable"
        access:
          read: true
        test: test
        }).models().startup().io.listen(port)
      return samjs.state.onceStarted.then ->
        config = reload("samjs-client")({
          url: url
          ioOpts:
            reconnection: false
            autoConnect: false
          })().config

    after ->
      samjs.shutdown()

    it "should be connected", ->
      return config.onceLoaded

    it "should be possible to retrieve values", ->
      config.get "testable"
      .then (result) -> should.not.exist result

    it "should be impossible to retrieve unreadable values",  ->
      config.get "unreadable"
      .then (result) -> should.not.exist result
      .catch -> true

    it "should be possible to test values",  ->
      test1 = config.test "testable", "rightValue"
      test2 = new samjs.Promise (resolve) ->
        config.test "testable", "wrongValue"
        .catch (e) ->
          resolve()
      samjs.Promise.all [test1,test2]

    it "should be impossible to test unwriteable values", ->
      config.test "unwriteable", "rightValue"
      .then (result) -> should.not.exist result
      .catch (e) -> true

    it "should be possible to set values", ->
      config.set "testable", "rightValue"
      .then ->
        config.get "testable"
      .then (result) ->
        result.should.equal "rightValue"
    it "should be impossible to set unwriteable values", ->
      config.set "unwriteable", "rightValue"
      .then (result) -> should.not.exist result
      .catch (e) -> true
