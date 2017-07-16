# out: ../lib/startup.js
hooks = ["startup"]
expose = (server) ->
  throw new Error "already started up, shutdown first" if @started
  @started = true
  @server = server if server?
  await @before.startup()
  @debug.startup "processing"
  io = @io ?= @socketio(@server)
  @debug.startup "finished"
  await @after.startup(io)
  return io

module.exports = expose: expose, hooks: hooks, tests: (should) ->
  it "should startup", => @finished
