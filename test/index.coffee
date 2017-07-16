chai = require "chai"
chai.use(require "chai-as-promised")
should = chai.should()

io = require "socket.io"
ioClient = require "socket.io-client"

port = 3030
url = "http://localhost:"+port+"/"

describe "socket-io", =>
  it "should work", (done) =>
    server = io(port)
    connection = ioClient(url,{reconnection:false,autoConnect:false})
    connection.once "connect", ->
      connection.close()
      server.close()
      server.httpServer.on "close", done
    connection.open()

Samjs = require("../src")

test = (name, o) =>
  if o.tests?
    describe name, =>
      samjs = new Samjs o.testsConfig
      before => samjs.finished
      after => samjs.shutdown()
      o.tests.call samjs, should
describe "samjs", =>
  for name in [
                "_helper"
                "hooks"
                "plugins"
                "options"
                "configs"
                "models"
                "startup"
                "shutdown"
                ]
     test name, require("../src/#{name}")
  test "client", require("../client-src/test")