port = 3037
url = "http://localhost:"+port+"/"
testConfigFile = "./test/testConfig.json"
Samjs = require "./index"
module.exports = 
  testsConfig:
     options: {config:testConfigFile}
     configs: {name: "test"}
  tests: (should) ->
    samjs = null
    before =>
      @io.listen(port)
      samjs = new Samjs(url:url,io:{reconnection:false})
      return samjs.finished
    after =>
      samjs.close() 
    it "should work", =>
      await samjs.config.set "test", "setTestClient"
      samjs.config.get("test").should.eventually.equal "setTestClient"
        