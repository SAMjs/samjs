chai = require "chai"
should = chai.should()
samjs = require "../src/main"
reload = require "simple-reload"
fs = samjs.Promise.promisifyAll(require("fs"))

port = 3030
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
  before (done) ->
    samjs.reset()
    fs.unlinkAsync testConfigFile
    .catch -> return true
    .finally ->
      done()
  describe "configInterface", ->
    before (done) ->
      samjs.plugins().options({config:testConfigFile}).configs({
        name: "testable"
        read: true
        write: true
        test: test
      },{
        name: "unreadable"
        write: true
      },{
        name: "unwriteable"
        read: true
        test: test
        }).models().startup().io.listen(port)
      samjs.state.onceStarted.then ->
        config = reload("samjs-client")({
          url: url
          ioOpts:
            reconnection: false
            autoConnect: false
          })().config
        done()

    after (done) ->
      samjs.shutdown().then -> done()
    it "should be possible to retrieve values", (done) ->
      config.get "testable"
      .then (result) ->
        should.not.exist result
        done()
      .catch done
    it "should be impossible to retrieve unreadable values", (done) ->
      config.get "unreadable"
      .catch (e) ->
        done()
    it "should be possible to test values", (done) ->
      test1 = config.test "testable", "rightValue"
      test2 = new samjs.Promise (resolve) ->
        config.test "testable", "wrongValue"
        .catch (e) ->
          resolve()
      samjs.Promise.all [test1,test2]
      .then -> done()
      .catch done
    it "should be impossible to test unwriteable values", (done) ->
      config.test "unwriteable", "rightValue"
      .catch (e) ->
        done()
    it "should be possible to set values", (done) ->
      config.set "testable", "rightValue"
      .then ->
        config.get "testable"
      .then (result) ->
        result.should.equal "rightValue"
        done()
      .catch done
    it "should be impossible to set unwriteable values", (done) ->
      config.set "unwriteable", "rightValue"
      .catch (e) ->
        done()
