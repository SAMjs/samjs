hooks = ["shutdown"]
expose = ->
  @debug.shutdown "processing"
  await @before.shutdown(@io)
  if @io?.engine? 
    @io.close()
    await new @Promise (resolve) =>
      @io.httpServer.once "close", =>
        @debug.core("server closed")
        setTimeout resolve, 50
  @started = false
  @debug.shutdown "finished"
  await @after.shutdown()


module.exports = expose: expose, hooks: hooks, testsConfig: {}, tests: (should) ->
  ioClient = require "socket.io-client"
  port = 3035
  url = "http://localhost:"+port+"/"
  it "should work", => new @Promise (resolve) => 
    @io.listen(port)
    socket = ioClient(url,{reconnection:false,autoConnect:false})
    socket.once "connect", =>
      socket.once "disconnect", => 
        resolve()
      @shutdown()
    socket.open()
