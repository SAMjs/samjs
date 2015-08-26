chai = require "chai"
should = chai.should()
samjs = require "../src/main"
someKey = "someKey"
someVal = "someVal"
describe "samjs", ->
  beforeEach ->
    samjs.reset()
  describe "helper", ->
    describe "merge", ->
      it "should work", ->
        dest = {}
        src = someKey: someVal
        result = samjs.helper.merge dest:dest, src: src
        result.should.equal dest
        dest.should.not.equal src
        should.exist dest[someKey]
        dest[someKey].should.equal someVal
      it "should merge deep", ->
        dest = {}
        src = someKey: someKey: someKey: someVal
        samjs.helper.merge dest:dest, src: src
        should.exist dest[someKey]
        should.exist dest[someKey][someKey]
        should.exist dest[someKey][someKey][someKey]
        dest[someKey][someKey][someKey].should.equal someVal
      it "should work with overwrite prop", ->
        dest = someKey: "something"
        src = someKey: someVal
        samjs.helper.merge dest:dest, src: src
        dest[someKey].should.equal "something"
        samjs.helper.merge dest:dest, src: src, overwrite: false
        dest[someKey].should.equal "something"
        samjs.helper.merge dest:dest, src: src, overwrite: true
        dest[someKey].should.equal someVal
    describe "clone", ->
      it "should work with objects", ->
        src = someKey:someVal
        dest = samjs.helper.clone src
        dest.should.not.equal src
        should.exist dest[someKey]
        dest[someKey].should.equal someVal
      it "should work deep", ->
        src = someKey: someKey: someVal
        dest = samjs.helper.clone src
        dest.should.not.equal src
        should.exist dest[someKey]
        dest[someKey].should.not.equal src[someKey]
        should.exist dest[someKey][someKey]
        dest[someKey][someKey].should.equal someVal
      it "should work with arrays", ->
        src = [someVal]
        dest = samjs.helper.clone src
        dest.should.not.equal src
        should.exist dest[0]
        dest[0].should.equal someVal
      it "should work with deep arrays", ->
        src = [someKey:someVal]
        dest = samjs.helper.clone src
        dest.should.not.equal src
        should.exist dest[0]
        dest[0].should.not.equal src[0]
        dest[0][someKey].should.equal someVal
    describe "inOrder", ->
      it "is tested in main"
    describe "parseSplats", ->
      it "should work", ->
        src = [someVal]
        dest = samjs.helper.parseSplats src
        dest.should.equal src
        dest = samjs.helper.parseSplats [src]
        dest.should.equal src
