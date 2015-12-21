# out: ../lib/options.js
module.exports = (samjs) -> samjs.options = (options) ->
  samjs.helper.inOrder("options")
  samjs.lifecycle.beforeOptions options
  samjs.debug.options("processing")
  if options?
    samjs.options = samjs.helper.merge({
      dest: samjs.options
      src: options
      overwrite: true
      })
  defaults = [config: "config.json"]
  for plugin in samjs._plugins
    if plugin.options?
      plugin.debug("got default options")
      defaults.unshift plugin.options
  samjs.options.setDefaults = (overwrite=true) ->
    for def in defaults
      samjs.options = samjs.helper.merge({
        dest: samjs.options
        src: def
        overwrite: overwrite
        })
  samjs.options.setDefaults(false)
  samjs.lifecycle.options options
  samjs.debug.options("finished")
  samjs.expose.configs()
  return samjs
