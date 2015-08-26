chai = require "chai"
should = chai.should()
samjs = require "../src/main"
ioClient = require "socket.io-client"
port = 3031
url = "http://localhost:"+port+"/"

describe "samjs", ->
  beforeEach ->
    samjs.reset()
  describe "startup", ->
    it "should start installation if required - tested in install"
    it "should startup", (done) ->
      samjs.plugins().options().configs().models().startup().started
      .then -> done()
    it "should start plugins ", (done) ->
      samjs.plugins({startup: done}).options().configs().models().startup()
    it "should expose a config - tested in configInterface"
    it "should expose a model interface for a model", (done) ->
      samjs.plugins().options().configs().models({
        name:"test"
        interfaces:
          test: (socket) ->
            socket.on "test", ->
              socket.emit "test"
        }).startup().io.listen(port)
      socket = ioClient(url,
                      {reconnection:false,autoConnect:false})
      socket.once "connect", ->
        model = socket.io.socket("/test")
        model.open()
        model.once "test", ->
          socket.close()
          samjs.shutdown()
          .then -> done()
          .catch done
        model.emit "test"
      socket.open()
  after ->
    samjs.shutdown?()
