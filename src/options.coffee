{merge} = require "./_helper"
hooks = ["options"]

expose = (options) ->
  await @before.options(options)
  @debug.options("processing")
  if options?
    @options = merge(@options, options, true)
  @options.config ?= "config.json"
  @options.dev ?= process.env.NODE_ENV != "production"
  await @after.options(@options)
  @debug.options("finished")

module.exports = 
  expose: expose
  hooks: hooks
  testsConfig:
    options: test: "test"
  tests: (should) ->
    it "should work", =>
      @options.test.should.equal "test"
    it "should have defaults", =>
      @options.config.should.equal "config.json"
    it "should be changeable", =>
      @options.config = "someVal"
      @options.config.should.equal("someVal")
    