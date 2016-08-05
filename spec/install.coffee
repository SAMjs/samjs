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
  before (done) ->
    samjs.reset()
    fs.unlinkAsync testConfigFile
    .catch -> return true
    .finally ->
      done()

  describe "install", ->
    client = null
    connect = null
    install = null
    promised = {}
    before (done) ->
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
      connect = reload("samjs-client")({
        url: url
        ioOpts:
          reconnection: false
          autoConnect: false
        })
      done()

    after (done) ->
      samjs.shutdown().then -> done()

    it "should trigger onceConfigure on server-side", (done) ->
      samjs.state.onceConfigure.then -> done()

    it "should be connectable by client", (done) ->
      client = connect()
      install = client.install
      install.onceLoaded
      .return done()
      .catch done

    it "should be in config mode client-side", (done) ->
      install.onceConfigure
      .then (nsp) ->
        nsp.should.equal "/configure"
        return install.isInConfigMode()
      .then (nsp) ->
        nsp.should.equal "/configure"
        done()

    it "should reject a false config", (done) ->
      install.onceConfigure
      .return install.test("testable","wrongValue")
      .catch (e) ->
        e.message.should.equal "wrongConfig"
        done()

    it "should not save a false config", (done) ->
      install.onceConfigure
      .return install.set("testable","wrongValue")
      .catch (e) ->
        e.message.should.equal "wrongConfig"
        done()

    it "should save a proper config", (done) ->
      install.onceConfigure
      .return install.set("testable","rightValue")
      .then samjs.configs["testable"]._get
      .then (str) ->
        str.should.equal "rightValue"
        done()
      .catch done

    it "should be configured server-side", (done) ->
      samjs.state.ifConfigured().then -> done()

    it "should emit configured and install server-side", (done) ->
      samjs.Promise.all([samjs.state.onceConfigured,samjs.state.onceInstall])
      .return done()

    it "should be configured client-side", (done) ->
      install.onceConfigured
      .then done
      .catch done

    it "should be in install mode client-side", (done) ->
      install.onceInstall
      .then (nsp) ->
        nsp.should.equal "/install"
        return install.isInInstallMode()
      .then (nsp) ->
        nsp.should.equal "/install"
        done()

    it "should reject a false new installation", (done) ->
      install.onceConfigured
      .then ->
        install.isInInstallMode()
        .then (nsp) ->
          client.io.nsp(nsp).getter("set",false)
      .catch (err) ->
        err.message.should.equal "wrongModel"
        done()

    it "should save a proper new installation", (done) ->
      install.onceConfigured
      .then ->
        install.isInInstallMode()
        .then (nsp) ->
          client.io.nsp(nsp).getter("set",true)
      .then -> done()
      .catch done

    it "should trigger onceInstalled server-side", (done) ->
      samjs.state.onceInstalled.then -> done()

    it "should be installed client-side", (done) ->
      install.onceInstalled
      .then done
      .catch done

    it "should trigger onceStarted after install", (done) ->
      samjs.state.onceStarted.then -> done()
