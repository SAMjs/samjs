# out: ../lib/configs.js

listener = (config, socket) =>
  try
    await config.before.listen(socket)
  catch e
    return
  name = config.name
  socket.join(name)
  socket.on name + ".test", (request, cb) =>
    config.test(data: request, socket: socket)
    .then ({data}) -> success:true , content:data
    .catch (err)   -> success:false, content:err?.message
    .then cb
  socket.on name + ".get", (request, cb) =>
    config.get(socket: socket)
    .then ({data}) -> success:true , content:data
    .catch (err)   -> success:false, content:err?.message
    .then cb
  socket.on name + ".set", (request, cb) =>
    config.set(data: request, socket: socket)
    .then ({data}) ->
      socket.to(name).broadcast.emit "updated", name
      success:true , content:data
    .catch (err)   -> success:false, content:err?.message
    .then cb
  await config.after.listen(socket)

class Config
  constructor: (options) ->
    if not options or not options.name
      throw new Error("config needs 'name' property")
    if options.test
      @_test = options.test
      delete options.test
    Object.assign @, plugins: [], options
    @samjs.hookup @
    @hooks.register ["get","set","test","listen"]
    _listener = listener.bind(@)
    @samjs.helper.hookInterface @samjs, "config", listener.bind(null, @)
    return @

  getBare: (o = {}) ->
    throw new Error "config #{@name} not set" unless @data?
    o.data = @data
    return o
      
  get: (o = {}) ->
    await @before.get(o)
    try
      await @getBare(o)
    catch
      o.data = null
    await @after.get(o)
    return o

  set: (o) ->
    o.oldData = @data
    await @_test o
    await @before.set o
    try
      config = await @fs.readJson @samjs.options.config
    catch
      config = {}
    config[@name] = @data = o.data
    await @fs.writeJson @samjs.options.config, config
    await @after.set o
    return o

  _test: (o) -> return null
  test: (o) ->
    await @before.test o
    await @_test o
    await @after.test o
    return o


{parseSplats} = require "./_helper"
hooks = ["configs"]

expose = (configs...) ->
  configs = parseSplats(configs)
  await @before.configs(configs)
  @debug.configs("processing")
  try
    data = await @fs.readJson(@options.config)
  catch e
    @debug.configs e
    data = {}
  for config in configs
    name = config.name
    @debug.configs "setting configs.#{name}"
    config.data = data[name]
    config.fs = @fs
    config.samjs = @
    @configs[name] = new Config config
  await @after.configs(@configs)
  @debug.configs("finished")

module.exports = 
  expose: expose
  hooks: hooks
  testsConfig:
    options: config: "test/testConfig.json"
    configs:[
      {name:"createable", someProp: "data"}
      {name:"getBare"}
      {name:"setable"}
      {name:"testable", test: ({data}) => throw new Error "reject" if data == "reject"}
      ]
  tests: (should) ->
    after => @fs.remove "test/testConfig.json"
    it "should be createable", =>
      should.exist (config = @configs.createable)
      config.someProp.should.equal "data"
      config.hooks.register "test"
      return new @Promise (resolve) =>
        config.before.test.call resolve
        config.before.test()
    it "should reject getBare",  =>
      should.Throw (=>@configs.getBare.getBare()), "config getBare not set"

    it "should be setable and getable",  =>
      await @configs.setable.set(data:"testData2")
      {data} = await @configs.setable.get()
      data.should.equal("testData2")

    it "should be testable",  =>
      await @configs.testable.test(data:"shouldWork")
      @configs.testable.test(data:"reject")
      .then => throw new Error "should get rejected"
      .catch (e) => 
        e.message.should.equal "reject"
        return true

    it "should save properly with custom config file", =>
      await @configs.setable.set(data: "fileRead")
      data = await @fs.readJson "test/testConfig.json"
      data.setable.should.equal "fileRead"

    describe "interface", =>
      ioClient = require "socket.io-client"
      port = 3036
      url = "http://localhost:"+port+"/"

      it "should be hooked up", => new @Promise (resolve) =>
        @io.listen(port)
        socket = ioClient(url+"config",{reconnection:false,autoConnect:false}) 
        socket.once "connect", =>
          socket.emit "setable.set", "setTest", (result) =>
            result.success.should.be.true
            result.content.should.equal "setTest"
            socket.emit "setable.get", null, (result) =>
              result.success.should.be.true
              result.content.should.equal "setTest"
              resolve()
        socket.open()