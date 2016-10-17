chai = require "chai"
should = chai.should()
samjs = require "../src/main"
reload = require "simple-reload"
fs = samjs.Promise.promisifyAll(require("fs"))

port = 3030
url = "http://localhost:"+port+"/"

testConfigFile = "test/testConfig.json"

testConfig = (value) ->
  return new samjs.Promise (resolve,reject) ->
    if value == "rightValue"
      resolve()
    else
      reject(new Error "wrongConfig")
testModel = () ->
  return new samjs.Promise (resolve,reject) =>
    if @value
      resolve()
    else
      reject(new Error "wrongModel")
describe "samjs", ->
  before ->
    samjs.reset()
    return fs.unlinkAsync testConfigFile
    .catch -> return true


  describe "install", ->
    client = null
    install = null
    promised = {}
    before  ->
      samjs.plugins().options({config:testConfigFile}).configs({
        name: "testable"
        isRequired: true
        test: testConfig
      }).models({
        name:"testable"
        isRequired: true
        value: false
        test: testModel
        interfaces: []
        installInterface: (socket) ->
          socket.on "set", (request) =>
            if request?.content? and request.token?
              if request.content
                @value = request.content
                response = success:true, content:request.content
                samjs.state.checkInstalled()
              else
                response = success:false, content: "wrongModel"
              socket.emit "set.#{request.token}", response
          return -> socket.removeAllListeners "set"
        }).startup().io.listen(port)
      client = reload("samjs-client")({
        url: url
        ioOpts:
          reconnection: false
          autoConnect: false
        })()

    after ->
      samjs.shutdown?()

    it "should trigger onceConfigure on server-side", ->
      samjs.state.onceConfigure

    it "should be connectable by client", ->
      install = client.install
      install.onceLoaded

    it "should be in config mode client-side", ->
      install.onceConfigure
      .then (nsp) ->
        nsp.should.equal "/configure"
        return install.isInConfigMode()
      .then (nsp) ->
        nsp.should.equal "/configure"


    it "should reject a false config", ->
      install.onceConfigure
      .return install.test("testable","wrongValue")
      .catch (e) ->
        e.message.should.equal "wrongConfig"

    it "should not save a false config", ->
      install.onceConfigure
      .return install.set("testable","wrongValue")
      .catch (e) ->
        e.message.should.equal "wrongConfig"


    it "should save a proper config",  ->
      install.onceConfigure
      .return install.set("testable","rightValue")
      .then samjs.configs["testable"]._get
      .then (str) ->
        str.should.equal "rightValue"


    it "should be configured server-side", ->
      samjs.state.ifConfigured()

    it "should emit configured and install server-side", ->
      samjs.Promise.all([samjs.state.onceConfigured,samjs.state.onceInstall])

    it "should be configured client-side", ->
      install.onceConfigured

    it "should be in install mode client-side", ->
      install.onceInstall
      .then (nsp) ->
        nsp.should.equal "/install"
        return install.isInInstallMode()
      .then (nsp) ->
        nsp.should.equal "/install"

    it "should reject a false new installation", ->
      install.onceConfigured
      .then ->
        install.isInInstallMode()
        .then (nsp) ->
          client.io.nsp(nsp).getter("set",false)
      .catch (err) ->
        err.message.should.equal "wrongModel"

    it "should save a proper new installation", ->
      install.onceConfigured
      .then ->
        install.isInInstallMode()
        .then (nsp) ->
          client.io.nsp(nsp).getter("set",true)


    it "should trigger onceInstalled server-side",  ->
      samjs.state.onceInstalled

    it "should be installed client-side",  ->
      install.onceInstalled

    it "should trigger onceStarted after install",  ->
      samjs.state.onceStarted
