chai = require "chai"
should = chai.should()
samjs = require "../src/main"
describe "samjs", ->
  describe "models", ->
    describe "simple",->
      beforeEach -> samjs.reset().plugins().options().configs()
      it "should throw on empty, nameless or interfaceless", ->
        (->samjs.models({})).should.throw()
        (->samjs.models({interfaces:[(->)]})).should.throw()
        (->samjs.models({name:"test"})).should.throw()
      it "should throw interface not array", ->
        (->samjs.models({
          name:"test"
          interfaces:(->)
          })).should.throw()
      it "should work with splats", ->
        samjs.models(
          {name:"test",interfaces:[(->)]}
          {name:"test2",interfaces:[(->)]}
        )
        should.exist samjs.models.test
        should.exist samjs.models.test2
      it "should work with arrays", ->
        samjs.models([
          {name:"test",interfaces:[(->)]}
          {name:"test2",interfaces:[(->)]}
        ])
        should.exist samjs.models.test
        should.exist samjs.models.test2
      it "should throw on installInterface or test missing or are no function if required", ->
        (->samjs.models({
          name:"test"
          interfaces:[(->)]
          isRequired:true
          installInterface:(->)
          })).should.throw()
        (->samjs.models({
          name:"test"
          interfaces:[(->)]
          isRequired:true
          test:(->)
          })).should.throw()
        (->samjs.models({
          name:"test"
          interfaces:[(->)]
          isRequired:true
          installInterface:(->)
          test:true
          })).should.throw()
        (->samjs.models({
          name:"test"
          interfaces:[(->)]
          isRequired:true
          installInterface:true
          test:(->)
          })).should.throw()
    describe "plugin interaction", ->
      beforeEach ->
        samjs.reset()
      start = (plugins) ->
        samjs.plugins(plugins).options().configs()
      it "should take plugin defaults",->
        start(models: [
          {name:"test",interfaces:[(->)],isExisting: -> false}
          {name:"test2",interfaces:[(->)],value:"test2",isExisting: -> false}
          ])
        .models({name:"test2",interfaces:[(->)],value:"nottest2"})
        should.exist samjs.models["test"]
        samjs.models["test"].should.be.a("object")
        samjs.models["test"].class.should.equal("Model")
        should.exist samjs.models["test2"]
        samjs.models["test2"].should.be.a("object")
        samjs.models["test2"].class.should.equal("Model")
        samjs.models["test2"].value.should.equal("nottest2")
