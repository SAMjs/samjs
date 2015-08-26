chai = require "chai"
should = chai.should()
io = require "socket.io"
ioClient = require "socket.io-client"

port = 3030
url = "http://localhost:"+port+"/"


describe "socket-io", ->
  it "should work", (done) ->
    server = io(port)
    connection = ioClient(url,{reconnection:false,autoConnect:false})
    connection.once "connect", ->
      connection.close()
      server.close()
      server.httpServer.on "close", ->
        connection.close()
        setTimeout done,100
    connection.open()
