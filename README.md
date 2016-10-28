# SAM.js

Created to connect **S**ocket.io, **A**ngularJS and **M**ongoDB.

Now it is database and view framework agnostic, leaving a socket.io framework.

Browser client: [samjs-client](https://github.com/SAMjs/samjs-client)

#### Features

- only websockets
- plugable
- useful defaults
- multiple databases simultaniously

## data modeling
- **options**  
source-code-based / kept-in-memory data.
Used to set low-level options of the app, can only be changed by restarting.
Not accessible due websockets.

- **configs**  
file-based / kept-in-memory data
For structural data specific for your app, should be only changed sparsely by few persons.

- **models**  
Can be custom in-memory models or plugable database-based models.
Should be used for all data which changes on regular basis.

## Getting Started
```sh
npm install --save samjs
npm install --save-dev samjs-client
```
#### Simple example with koa server

```js
samjs = require "samjs"
koa = require("koa")()

server = require("http").createServer(koa.callback())

samjs
.plugins()
.options()
.configs({name:"item"})
.models()
.startup(server)

server.listen(3000)
#to close
#samjs.shutdown()

// in browser with e.g. webpack
samjs = require("samjs-client")()
samjs.config.set("item", "value")
.then(function(){
  //success
})
.catch(function(){
  //failure
})
// some other client  
samjs.config.on("item",function(){
  //item changed
  samjs.config.get("item")
  .then(function(response){
    response == "value" // true
  })
  .catch(function(){
    //failure
  })
}
```

## Available plugins

Name | Description
---: | ---
[samjs-auth](https://github.com/SAMjs/samjs-auth) | adds a configs-based user management, authentification mechanismen and authorization system for configs.
[samjs-files](https://github.com/SAMjs/samjs-files) | adds a model and interface for file/folder interaction
[samjs-files-auth](https://github.com/SAMjs/samjs-files-auth) | adds authorization for samjs-files
[samjs-mongo](https://github.com/SAMjs/samjs-mongo) | adds a model and interface for mongodb interaction
[samjs-mongo-auth](https://github.com/SAMjs/samjs-mongo-auth) | adds authorization for samjs-mongo
[samjs-auth-mongo](https://github.com/SAMjs/samjs-auth-mongo) | moves user management to mongodb. Adds groups.
[samjs-mongo-isOwner](https://github.com/SAMjs/samjs-mongo-isOwner) | Plugin for managing user owned documents in samjs-mongo.

## docs
Samjs is configured by several functions which must be called in order.
Startup order:
```js
samjs.plugins().options().configs().models().startup().io.listen(8080)
```

### Function: plugins
takes one or more plugin objects or an array of plugin objects. Returns `samjs`.
```js
samjs.plugins(require("samjs-files"),require("samjs-auth"))
// or
samjs.plugins([require("samjs-files"),require("samjs-auth")])
```
See [plugin api](#plugin-api) for detailed information to write your own plugin

### Function: options
takes a options object to overwrite the default values. Returns `samjs`.
```js
// only default in core is samjs.options.config == "config.json"
// to overwrite:
samjs.options({config:"settings.json"})
```

### Function: configs
takes one or more config objects or an array of config objects. Returns `samjs`.
```js
samjs.configs({name:"paths"},{name:"users"})
// or
samjs.configs([{name:"paths"},{name:"users"}])
```
#### Props of a config object:

| Name | type | default | description |
| ---:| --- | ---| --- |
| name | String | - | (required) name of the config object. To access the config object after setup :`samjs.configs[name]`|
| access | Object | `{read:false,write:false}` | allowes to access this config value by client |
| test | Function | - | Function to test values for validity. Must return a promise which resolves on success and rejects on error.  |
| isRequired | Boolean | `false` | includes this config object in configuration phase. (see [lifecycle](#lifecycle)) |
| hooks | Object | - | functions to get called on specific interactions with this config object. |

#### actions:
After setup, each config object has 3 available actions: `set,get,test`. Each has a server-side version: `
_set,_get,_test`, which are not checking for authentification.

#### hooks:
hooks are functions which are called on specific actions.
They always have to return their arguments.

| Name |  arguments | description |
| ---:| ---| --- |
| beforeCreate | `options` | manipulate the options object before creation  |
| afterCreate | `options` | manipulate the options object after creation  |
| beforeSet | `{data, socket}` | used to authenticate a set request |
| before_Set | `{data, oldData}` | used to manipulate a set request |
| afterSet | `{data, oldData, socket}`  | called after a successfull set request from client |
| after_Set | `{data, oldData}` | called after each successfull set request |
| beforeGet | `{socket}` | used to authenticate a get request |
| after_Get | `data` | called after a successfull _get request  |
| afterGet | `{data, socket}` | called after a successfull get request from client |
| beforeTest | `{data, socket}` | used to authenticate a test request |
| afterTest | `{data, socket}` | called after a successfull test request from client |

example (how `samjs-auth` basically works):
```js
samjs.configs({name:"paths", hooks: {
  beforeSet: function(obj) {
    if (obj.client.auth != null
      && obj.client.auth.user != null
      && obj.client.auth.user.username == "root") {
        return obj
    }
    throw new Error "no permission"
  }}
})
```

### Function: models
takes one or more model objects or an array of model objects. Returns `samjs`.
```js
samjs.models(model1,model2)
// or
samjs.models([model1,model2])
```
#### Props of a model object:

| Name | type | default | description |
| ---:| --- | ---| --- |
| name | String | - | (required) name of the model object. To access the model object after setup :`samjs.models[name]`|
| interfaces | Object or array| - | see below. |
| isRequired | Boolean | `false` | includes this model object in installation phase. (see [lifecycle](#lifecycle)) |
| installInterface | Function | - | a socket.io interface which is used in installation phase if `isRequired` is `true` (see [installInterface](#installinterface)) |
| test | Function | - | a function to test if installation requirement is met, if `isRequired` is `true` |
| db | String | - | use a model-structure and interface from a plugin|


#### interfaces
Interfaces can be either a array or a key-value store
```js
// all interfaces in an array will listen one the "someModel" socket.io namespace
samjs.models({
  name: "someModel"
  value: "someValue"
  interfaces: [
    // will be in the "someModel" socket.io namespace
    function(socket){
      var model = this
      // model.name == "someModel" // true
      socket.on("get",function(request){
        if (request.token != null){
          socket.emit("get."+.request.token,{success:true, content:model.value})
        }
      })
    }
  ]
  })
// if you need to use another namespace use an object instead
samjs.models({
  name: "someModel"
  interfaces: {
    // either provide a single interface or a array of interfaces
    // will be in the "someOtherNamespace" socket.io namespace
    someOtherNamespace: function(socket){ //doSomething }
  }
  })
```
#### installInterface
```js
samjs.models({
  name: "someModel"
  installInterface: function(socket){
    var model = this # will be bound to model instance
    # will be in the 'install' socket-io namespace, specific listeners are required
    socket.on "someModel.set", function(request) =>
      if (request.token != null && request.content != null){
        # no authentification, will be only accessible in install mode
        model.test(request.content)
        .then(function(value){model.value = value})
        .then(function(value){return {success:true, content: value}}
        .catch(function(e){return {success:false, content: e.message}}
        .then(function(response){
          socket.emit("boilerplate.set."+request.token, response)
          if(response.success){
            samjs.state.checkInstalled() # will trigger a check if installation is finished
            }
          }
        }
    # must return a dispose function
    return function(){socket.removeAllListeners("someModel.set")}
  }
})
```

#### Function: startup
takes a optional `httpServer`, returns `samjs`.
```js
samjs.startup(someServer)
someServer.listen(8080)
// or
samjs.startup()
samjs.io.listen(8080)
```
#### Function: shutdown
returns `samjs`. Shuts samjs and socket.io down.

#### Function reset
returns `samjs`. Resets samjs instance. Useful for unit testing.

## Lifecycle
`samjs` emits several events during its lifecycle:

example:
```js
samjs.once("options",function(){console.log("options got called")})
```
#### Synchronous (configuration / after startup)
Name | Description
---: | ---
beforePlugins | emitted before `samjs.plugins()` is executed
plugins | emitted after `samjs.plugins()` is executed
beforeOptions | emitted before `samjs.options()` is executed
options |  emitted after `samjs.options()` is executed
beforeConfigs | emitted before `samjs.configs()` is executed
configs | emitted after `samjs.configs()` is executed
beforeModels | emitted before `samjs.models()` is executed
models | emitted after `samjs.models()` is executed
beforeStartup | emitted before `samjs.startup()` is executed
startup  | emitted after `samjs.startup()` is executed
beforeShutdown | emitted before `samjs.shutdown()` is executed
shutdown  | emitted after `samjs.shutdown()` is executed
beforeReset | emitted before `samjs.reset()` is executed
reset  | emitted after `samjs.reset()` is executed

#### Asynchronous (startup)

`samjs.startup` works like this:
```
Is samjs configured? (all configs with `isRequired` are set properly)
- start configuration if not
Execute all `startup` functions of all plugins
Execute all `startup` functions of all models
Is samjs installed? (all models with `isRequired` are set properly)
- start installation if not
expose all socket.io interfaces
```
Events:

Name | Description
---: | ---
beforeConfigure | emitted before configuration is set up and ready
configure | emitted after configuration is set up and ready
configured | emitted after configuration is done or when no configuration was necessary
beforeInstall | emitted before installation is set up and ready
install | emitted after installation is set up and ready
installed | emitted after installation is done or when no installation was necessary
started | emitted when samjs is properly started up

There are additional state promises which will fullfill once a state is reached:

Name | Description
---: | ---
onceConfigure | fullfilled once in configuration mode
onceConfigured | fullfilled once configuration is finished
onceInstall | fullfilled once in installation mode
onceInstalled | fullfilled once installation is finished
onceStarted | fullfilled once samjs is properly started up
onceConfigureOrInstall | fullfilled once in configuration or installation mode

example
```js
samjs.state.onceStarted.then(function(){
  // do something
  })
```

## Plugin api
see source code of [samjs-plugin-boilerplate](https://github.com/SAMjs/samjs-plugin-boilerplate) for a complete plugin api
