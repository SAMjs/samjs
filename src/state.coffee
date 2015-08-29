# out: ../lib/state.js

module.exports = (samjs) -> samjs.state = new class State
  constructor: ->
    @onceConfigured = new samjs.Promise (resolve) =>
      samjs.once "configs", =>
        @ifConfigured()
        .then resolve
        .catch ->
          samjs.once "configured", resolve
    @onceInstalled = new samjs.Promise (resolve) =>
      @onceConfigured.then =>
        samjs.once "models", =>
          @ifInstalled()
          .then resolve
          .catch ->
            samjs.once "installed", resolve
  ifConfigured: (exclude) ->
    required = []
    for k,v of samjs.configs
      if v? and v.isRequired and v._test? and v.name != exclude
        required.push v._getBare().then(v._test)
    return samjs.Promise.all(required)
      .catch (e) -> throw new Error "not configured"
  ifInstalled: ->
    required = []
    for k,v of samjs.models
      if v?.isRequired? and v.isRequired and v.test?
        required.push v.test.bind(v)()
    return samjs.Promise.all(required)
      .catch (e) -> throw new Error "not installed"
