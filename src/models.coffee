# out: ../lib/models.js

class Model
  constructor: (options) ->
    if not options or not options.name
      throw new Error("config needs 'name' property")
    Object.assign @, plugins: [], options
    @samjs.hookup @
    return @

{parseSplats} = require "./_helper"
hooks = ["models"]

expose = (models...) ->
  models = parseSplats(models)
  await @before.models(models)
  @debug.models("processing")
  for model in models
    name = model.name
    @debug.models "setting models.#{name}"
    model.samjs = @
    @models[name] = new Model model
  await @after.models(@models)
  @debug.models("finished")

module.exports = 
  expose: expose
  hooks: hooks
  testsConfig: 
    models: name: "test", someProp: "data"
  tests: (should) ->
    it "should work", =>
      should.exist (model = @models.test)
      model.someProp.should.equal "data"
      model.hooks.register "test"
      return new @Promise (resolve) =>
        model.before.test.call resolve
        model.before.test()