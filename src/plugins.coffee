{parseSplats} = require "./_helper"
hooks = ["plugins"]

expose = (plugins...) ->
  plugins = parseSplats(plugins)
  await @before.plugins(plugins)
  @debug.plugins("processing")
  for plugin in plugins
    plugin(@)
  await @after.plugins()
  @debug.plugins("finished")

module.exports = expose: expose, hooks: hooks, tests: (should) ->
  it "should call",  =>
    @plugins (samjs) =>
      @should.equal samjs