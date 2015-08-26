chai = require "chai"
should = chai.should()
samjs = require "../src/main"
ioClient = require "socket.io-client"
port = 3031
url = "http://localhost:"+port+"/"

describe "samjs", ->
  beforeEach ->
    samjs.reset()
  describe "shutdown", ->
    it "should work", (done) ->
      samjs.plugins().options().configs().models().startup().io.listen(port)
      socket = ioClient(url,
                      {reconnection:false,autoConnect:false})
      socket.once "connect", ->
        socket.once "disconnect", ->
          done()
        samjs.shutdown()
      socket.open()
