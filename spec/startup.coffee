chai = require "chai"
should = chai.should()
samjs = require "../src/main"
ioClient = require "socket.io-client"
port = 3031
url = "http://localhost:"+port+"/"

describe "samjs", ->
  describe "startup", ->
    beforeEach ->
      samjs.reset()
    it "should start installation if required - tested in install"
    it "should startup",  ->
      samjs.plugins().options().configs().models().startup()
      return samjs.state.onceStarted
    it "should start plugins ", (done) ->
      samjs.plugins({startup: done}).options().configs().models().startup()
    it "should expose a config - tested in configInterface"
    it "should expose a model interface for a model", (done) ->
      @timeout(5000)
      samjs.plugins().options().configs().models({
        name:"test"
        interfaces:[
          (socket) ->
            socket.on "test", ->
              socket.emit "test"
            ]
        }).startup().io.listen(port)
      socket = ioClient(url,
                      {reconnection:false,autoConnect:false})
      socket.once "connect", ->
        model = ioClient.Manager("/test")
        model.once "test", ->
          socket.close()
          done()
        model.emit "test"
      socket.open()
  after ->
    samjs.shutdown?()
